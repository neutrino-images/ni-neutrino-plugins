
#include <stdlib.h>
#include <string.h>
#include <signal.h>

#include <sys/socket.h>

#include <fstream>
#include <sstream>
#include <iostream>
#include <unistd.h>

#include "FritzCallMonitor.h"
#include "connect.h"


CFCM* CFCM::getInstance()
{
	static CFCM* instance = NULL;
	if(!instance)
		instance = new CFCM();
	return instance;
}

CFCM::CFCM()
{
	cconnect = CConnect::getInstance();

	//default parameters
	conf["MSGTIMEOUT"]		= "-1";
	conf["BACKWARDSEARCH"]	= "1";
	conf["EASYMODE"]		= "0";
	conf["SEARCH_MODE"]		= "0";
	conf["SEARCH_INT"]		= "300";
	conf["AD_FLAGFILE"]		= "/var/etc/.call";
	conf["SEARCH_QUERY"]	= "&var=tam:settings/TAM0/NumNewMessages";
	conf["MSGTYPE"]			= "nmsg";
	conf["PORT"]			= "1012";
	conf["WEB_PORT"]		= "80";
	conf["SEARCH_PORT"]		= "80";
	conf["DEBUG"]			= "1";
	conf["FRITZBOXIP"]		= "fritz.box";
	conf["SEARCH_ADDRESS"]	= "www.goyellow.de";
	conf["ADDRESSBOOK"]		= "/var/tuxbox/config/FritzCallMonitor.addr";

	read_conf(CONFIGFILE);

	// using atoi instead of stoi because of error handling
	debug			= std::atoi(conf["DEBUG"].c_str());
	BackwardSearch	= std::atoi(conf["BACKWARDSEARCH"].c_str());
	msgtimeout		= std::atoi(conf["MSGTIMEOUT"].c_str());
	easymode		= std::atoi(conf["EASYMODE"].c_str());
	FritzPort		= std::atoi(conf["PORT"].c_str());
	SearchPort		= std::atoi(conf["SEARCH_PORT"].c_str());
	searchmode		= std::atoi(conf["SEARCH_MODE"].c_str());
	searchint		= std::atoi(conf["SEARCH_INT"].c_str());

	//reinit after reading configfile
	cconnect->setDebug(debug);
	cconnect->setFritzAdr(conf["FRITZBOXIP"].c_str());
	cconnect->setFritzPort(std::atoi(conf["WEB_PORT"].c_str()));
}

CFCM::~CFCM()
{
	//
}

void CFCM::FritzCall()
{
	char Buff1[BUFFERSIZE];
	int sockfd = 0;
	int loop = 0;
	int len = 0;

	int i;
	char* item[MAXITEM];

	while(!loop)
	{
		sockfd = cconnect->connect2Host(conf["FRITZBOXIP"].c_str(), FritzPort);

		if (sockfd > 0) {
			printf("[%s] - Socked (%i) connected to %s\n", FCMNAME, sockfd, easymode?"EasyBox":"FritzBox");
			loop=1;
		}
		else
			sleep(5);
	}

	if(!easymode)
	{
	    do {
		bzero(Buff1, sizeof(Buff1));
		if((len = recv(sockfd, Buff1, sizeof(Buff1), 0)) <= 0) {
			printf("[%s] - recv error\n", FCMNAME);
			break;
		}
#if 0
		/*
		 *	Ankommender Anruf
		 *	28.08.10 10:21:37;RING;2;040xxx;123x;ISDN;
		 *	Verbunden
		 *	28.08.10 10:25:40;CONNECT;0;4;040xxx;
		 *
		 *	Ankommender Anruf / Nummer unterdrückt
		 *	28.08.10 10:22:07;RING;0;;123x;ISDN;
		 *	Verbunden
		 *	28.08.10 10:24:37;CONNECT;0;4;;
		 *
		 *	Abgehender Anruf
		 *	28.08.10 10:28:48;CALL;1;4;123x;040xxx;ISDN;
		 *
		 *	Getrennt
		 *	28.08.10 10:28:51;DISCONNECT;1;0;
		 */
#endif
		printf("[%s] - %s",FCMNAME, Buff1);

		i=0;
		//item[0]="not used";
		char* token = strtok(Buff1, ";");
		while (token != NULL)
		{
			item[i+1] = token;
			token = strtok(NULL, ";");
			if (debug) {
				if ( i != 0 )
					printf("%i - %s\n", i, item[i]);
			}
			if (i >= MAXITEM) break;
			i++;
		 }

		if (strcmp(item[2], "RING") == 0) //incomming call
		{
			if ( i == 5+1) //hidden number
			{
				strcpy(CallFrom, "Unbekannt");
				strcpy(CallTo, item[4]);
			}
			else
			{
				strcpy(CallFrom, item[4]);
				strcpy(CallTo, item[5]);
			}
			printf("[%s] - Eingehender Anruf von %s an %s\n", FCMNAME, CallFrom, CallTo);

			for (i=0; i < (int)(sizeof(msnnum)/sizeof(msnnum[0])); i++)
			{
				if ((i==0 && strcmp(msnnum[i].msn, "") == 0) || strcmp(msnnum[i].msn, CallTo) == 0)
				{
					if(strlen(msnnum[i].msnName) != 0)
						strcpy(CallToName,msnnum[i].msnName);

					if (BackwardSearch && strcmp(CallFrom, "Unbekannt") != 0)
					{
						search(CallFrom);
					}
					else
						sendMSG(0);
				}
			}
		}
	    } while (loop);
	}
	else //EasyBox mode
	{
	    do {
		bzero(Buff1, sizeof(Buff1));
		if((len = recv(sockfd, Buff1, sizeof(Buff1), 0)) <= 0) {
			printf("[%s] - recv error\n",FCMNAME );
			break;
		}
#if 0
		//strcpy(Buff1,"CID: *DATE*06072011*TIME*1929*LINE**NMBR*092XXXXXXX*MESG*NONE*NAME*NO NAME*\n");

		/*
		 * 	EasyBox Caller ID
		 *
		 * 	Ankommender Anruf
		 * 	CID: *DATE*06072011*TIME*1929*LINE**NMBR*092XXXXXXX*MESG*NONE*NAME*NO NAME*
		 *
		 * 	Ankommender Anruf / Nummer unterdrückt
		 * 	CID: *DATE*01072011*TIME*2007*LINE**NMBR*Privat*MESG*NONE*NAME*NO NAME*
		 */
#endif
		printf("[%s] - %s",FCMNAME, Buff1);

		char* ptr;
		strcpy(CallFrom,"Unbekannt");
		strcpy(CallTo,"EasyBox");

		if ((ptr = strstr(Buff1, "CID:"))) //incomming call
		{
			if ((ptr = strstr(Buff1, "NMBR*")))
				sscanf(ptr + 5, "%63[^*]", (char *) &CallFrom);
			else if ((ptr = strstr(Buff1, "LINE*")))
				sscanf(ptr + 5, "%63[^*]", (char *) &CallTo);

			printf("[%s] - Eingehender Anruf von %s an %s\n", FCMNAME, CallFrom, CallTo);

			for (i=0; i < (int)(sizeof(msnnum)/sizeof(msnnum[0])); i++)
			{
				if ((i==0 && strcmp(msnnum[i].msn, "") == 0) || strcmp(msnnum[i].msn, CallTo) == 0)
				{
					if(strlen(msnnum[i].msnName) != 0)
						strcpy(CallToName,msnnum[i].msnName);

					if (BackwardSearch && strcmp(CallFrom, "Privat") != 0 && strcmp(CallFrom, "Unbekannt") != 0)
					{
						search(CallFrom);
					}
					else
						sendMSG(0);
				}
			}
		}
	    } while (loop);
	}
	close(sockfd);
	//loop if socked lost
	FritzCall();
}

int CFCM::search(const char *searchNO)
{
	char *found;
	char *line;
	ssize_t read;
	size_t len;
	ostringstream url;
	string output ="/tmp/fim.out";
	FILE* fd;

	url	<< conf["SEARCH_ADDRESS"] << "/suche/" << searchNO << "/-";

	memset(&address, 0, sizeof(address));

	if(search_AddrBook(CallFrom)) {
		sendMSG(1);
		return 0;
	}

	if (debug){printf("[%s] - searchURL: %s\n",FCMNAME, url.str().c_str());}

	string s = cconnect->post2fritz(url.str().c_str(),80 ,"", output);

	line=NULL;
	if((fd = fopen(output.c_str(), "r")))
	{
		while ((read = getline(&line, &len, fd)) != -1)
		{
			if ((found = strstr(line, "title=\"Zur Detailseite von&#160;")))
			{
				sscanf(found + 32, "%255[^\"]", (char *) &address.name);
			}

			if ((found = strstr(line, "\"postalCode\" content=\"")))
			{
				sscanf(found + 22, "%5[^\"]", (char *) &address.code);
			}

			if((found = strstr(line, "\"addressLocality\" content=\"")))
			{
				sscanf(found + 27, "%127[^\"]", (char *) &address.locality);
			}

			if((found = strstr(line, "address-icon ic_address svg-icon\"></span>")))
			{
				sscanf(found + 41, "%127[^,]", (char *) &address.street);
			}
		}
		fclose(fd);
	}
	if(line)
		free(line);

	if (debug){printf("[%s] - (%s) = %s, %s, %s %s\n",FCMNAME, searchNO, address.name, address.street, address.code, address.locality);}

	if(strlen(address.name)!=0)
	{
		sendMSG(strlen(address.name));

		// Save address to addressbook
		add_AddrBook(CallFrom);
	}
	else {
		printf("[%s] - no results for %s\n",FCMNAME, searchNO);
	}

	//sendMSG(0);

	return 0;
}

void CFCM::sendMSG(int caller_address)
{
	ostringstream msg;
	ostringstream txt;
	int i,j;
	const char *newline="%0A";
	const char *space="%20%20";

	if (caller_address)
	{
		msg	<< "Anrufer : " << CallFrom << (strlen(address.name)!=0 ? newline : "")
			<< space << address.name << (strlen(address.street)!=0 ? newline : "")
			<< space << address.street << (strlen(address.code)!=0 ? newline : "")
			<< space << address.code << space << address.locality << newline
			<< "Leitung : " << (strlen(CallToName)!=0 ? CallToName : CallTo);
	}
	else
	{
		msg	<< "Anrufer : " << CallFrom << newline
			<< "Leitung : " << (strlen(CallToName)!=0 ? CallToName : CallTo);
	}

	if(!conf["EXEC"].empty())
	{
		pid_t pid;
		signal(SIGCHLD, SIG_IGN);
		switch (pid = vfork())
		{
			case -1:
				perror("vfork");
				break;
			case 0:
				printf("[%s] - Execute -> %s\n",FCMNAME,conf["EXEC"].c_str());
				if(execl("/bin/sh", "sh", conf["EXEC"].c_str(), msg.str().c_str(), NULL))
				{
					perror("execl");
				}
				_exit (0); // terminate c h i l d proces s only
			default:
				break;
		}
	}

	for (i=0; i < (int)(sizeof(msnnum)/sizeof(msnnum[0])); i++)
	{
		if ( (i==0 && strcmp(msnnum[0].msn, "") == 0) || strcmp(msnnum[i].msn, CallTo) == 0)
		{
			for (j=0; j < (int)(sizeof(boxnum)/sizeof(boxnum[0])); j++)
			{
				if ((strcmp(boxnum[j].BoxIP, "") != 0)) {
					txt.str("");
					txt << msg.str() << ' ';

					char * ptr;
					char ip[20];
					int port = 80;

					if ((ptr = strstr(boxnum[j].BoxIP, ":"))) {
						sscanf(boxnum[j].BoxIP, "%19[^:]", ip);
						sscanf(ptr + 1, "%i", &port);
					}
					else {
						strcpy(ip,boxnum[j].BoxIP);
					}
					cconnect->get2box(ip, port, txt.str().c_str(), boxnum[j].logon, conf["MSGTYPE"].c_str(), msgtimeout);
				}
			}
		}
	}
}

int CFCM::search_AddrBook(const char *caller)
{
	FILE *fd;
	char *line_buffer;
	string search_str;
	ssize_t ptr;
	size_t len;
	int i=0;

	if(strlen(caller)!=0){
		search_str = (string) caller + "|";
	} else {
		return(0);
	}

	if(!(fd = fopen(conf["ADDRESSBOOK"].c_str(), "r"))) {
		perror(conf["ADDRESSBOOK"].c_str());
		return(0);
	}
	else
	{
		line_buffer=NULL;
		while ((ptr = getline(&line_buffer, &len, fd)) != -1)
		{
			i++;
			if (strstr(line_buffer, search_str.c_str()))
			{
				sscanf(line_buffer,"%*[^|]|%255[^|]|%127[^|]|%5[^|]|%127[^|]",
					(char *) &address.name,
					(char *) &address.street,
					(char *) &address.code,
					(char *) &address.locality);
				if (debug)
					printf("[%s] - \"%s\" found in %s[%d]\n", FCMNAME, caller, conf["ADDRESSBOOK"].c_str(), i);
				fclose(fd);
				if(line_buffer)
					free(line_buffer);
				return(1);
			}
		}
		if (debug)
			printf("[%s] - \"%s\" not found in %s\n", FCMNAME, caller, conf["ADDRESSBOOK"].c_str());

		fclose(fd);
		if(line_buffer)
			free(line_buffer);
	}
	return(0);
}

int CFCM::add_AddrBook(const char *caller)
{
	ofstream os(conf["ADDRESSBOOK"].c_str(), ios::out | ios::app);

	if (os.is_open())
	{
		os	<< caller << '|'
			<< address.name << '|'
			<< address.street << '|'
			<< address.code << '|'
			<< address.locality << '|' << endl;
		os.close();
	}
	else
	{
		return(0);
	}

	return(1);
}

vector<string> CFCM::split(stringstream& str,const char& delim)
{
	string line, cell;
	vector<string> result;

	while(getline(str,cell,delim))
	{
		result.push_back(cell);
		//printf("cell=%s\n",cell.c_str());
	}
	return result;
}

string CFCM::create_map(string& k, const string& t, string& v, map<string, vector<string> >& m)
{
	// cleanup keys with no values
	if(v.empty())
	{
		k.clear();
		return("");
	}

	string key;
	string::size_type begin = k.find(t);

	if(begin != string::npos)
	{
		key = k.substr(t.size());
		k.erase(t.size());

		// modify value
		cconnect->StringReplace(v,":;,",";");
		cconnect->StringReplace(v," ;\t","");

		// create tmp vector
		stringstream is(v);
		vector<string> tmp = split(is,';');

		// copy tmp vector into map
		m[key].swap(tmp);

		//debug
		//if(debug) cout << k << '[' << key << ']' << "=" << v << endl;
	}

	return(key);
}

string CFCM::create_map(string& k, const string& t, const string& v, map<string, string>& m)
{
	if(v.empty())
	{
		k.clear();
		return("");
	}

	string key;
	string::size_type begin = k.find(t);
	if(begin != string::npos)
	{
		key = k.substr(t.size());
		k.erase(t.size());

		m[key] = v;

		//debug
		//if(debug) cout << k << '[' << key << ']' << "=" << v << endl;
	}

	return(key);
}

void* CFCM::proxy_loop(void* arg)
{
	pthread_setcancelstate(PTHREAD_CANCEL_ENABLE,0);
	pthread_setcanceltype (PTHREAD_CANCEL_ASYNCHRONOUS,0);

	static_cast<CFCM*>(arg)->query_loop();
	return 0;
}

int CFCM::query_loop()
{
	sleep(10);

	while(1)
	{
		if(searchmode)
		{
			printf("[%s] - %s send query\n", FCMNAME, cconnect->timestamp().c_str());
			if(cconnect->get_login(conf["PASSWD"].c_str(), conf["USER"].c_str()))
			{
				cconnect->send_TAMquery(conf["AD_FLAGFILE"].c_str(),cconnect->getSid(),conf["SEARCH_QUERY"].c_str());
			}
		}

		if(!conf["DECTBOXIP"].empty())
		{
			cconnect->setFritzAdr(conf["DECTBOXIP"].c_str());
			printf("[%s] - %s getdevicelistinfos %s\n", FCMNAME, cconnect->timestamp().c_str(),conf["DECTBOXIP"].c_str());

			if(cconnect->get_login(conf["DECTPASSWD"].c_str(),conf["DECTUSER"].c_str()))
			{
				cconnect->smartHome(cconnect->getSid(),"getdevicelistinfos");
				cconnect->checkdevice(wp,dp);
				cconnect->cleardevice();
			}
			cconnect->setFritzAdr(conf["FRITZBOXIP"].c_str());
		}

		sleep(searchint);
	}
	return 0;
}

void CFCM::start_loop()
{
	if (searchmode || !conf["DECTBOXIP"].empty()) {
		if(!thrTimer) {
			printf("[%s] - %s Start Thread for checking FRITZ!Box (reload %i seconds)\n",FCMNAME, cconnect->timestamp().c_str(), searchint);
			pthread_create (&thrTimer, NULL, proxy_loop, this) ;
			pthread_detach(thrTimer);
		}
	}
}

void CFCM::stop_loop()
{
	if(thrTimer) {
		printf("[%s] - %s Stop Thread for checking FRITZ!Box\n", FCMNAME, cconnect->timestamp().c_str());
		pthread_cancel(thrTimer);
		thrTimer = 0;
	}
}

int CFCM::read_conf(const string& file)
{
	fstream fh;
	string s, key, value, inx;

	// clean table for reload
	//conf.clear();
	wp.clear();
	dp.clear();

	fh.open(file.c_str(), ios::in);

	if(!fh.is_open())
	{
		cout << "Error reading configfile \"" << file << "\"" << endl;
		return 1;
	}

	while (getline(fh, s))
	{
		string::size_type begin = s.find_first_not_of(" \f\t\v");

		// skip blank lines
		if (begin == string::npos)
			continue;

		// skip commentary
		if (string("#;").find(s[begin]) != string::npos)
			continue;

		// extract the key value
		string::size_type end = s.find('=', begin);
		// skip lines without "="
		if (end == string::npos)
			continue;
		key = s.substr(begin, end - begin);

		// trim key
		//key.erase(key.find_last_not_of(" \f\t\v") + 1);
		cconnect->StringReplace(key," ;[;];\f;\t;\v", "");

		// skip blank keys
		if (key.empty())
			continue;

		// extract and trim value
		begin = s.find_first_not_of(" \f\n\r\t\v", end);
		end   = s.find_last_not_of(" \f\n\r\t\v") + 1;
		value = s.substr(begin + 1, end - begin);
		cconnect->StringReplace(value," ;[;];\f;\t;\v", "");

		// *** special maps ***

		// not nice, better useing map instead of histical struct
		if(key.find("BOXIP_") == 0)
		{
			if (value.empty())
				continue;

			// key for struct
			int inx = key[key.length()-1] - '1';

			strcpy(boxnum[inx].BoxIP,value.c_str());

			//cout << key << "=" << value << endl;
			continue;
		}
		if(key.find("LOGON_") == 0)
		{
			if (value.empty())
				continue;

			// key for struct
			int inx = key[key.length()-1] - '1';

			strcpy(boxnum[inx].logon,value.c_str());

			//cout << key << "=" << value << endl;
			continue;
		}

		if(key.find("MSN_") == 0)
		{

			if (value.empty())
				continue;

			stringstream is(value);
			vector<string> tmp = split(is,'|');
			// key for struct
			int inx = key[key.length()-1] - '1';

			strcpy(msnnum[inx].msn, tmp[0].c_str());
			if(tmp.size() > 1) strcpy(msnnum[inx].msnName, tmp[1].c_str());

			//cout << key << "=" << value << endl;

			continue;
		}

		// create map for Comet temp
		inx = create_map(key, "DP", value, dp);
		if(!inx.empty())
			continue;

		// create map for Comet week
		inx = create_map(key, "WP", value, wp);
		if(!inx.empty())
			continue;

		// *** config map ***

		// create map for config
		if(!key.empty()) {
			conf[key] = value;

			cout << key << "=" << value << endl;
		}
	}
	fh.close();

	return 0;
}

void tokenize(std::string const &str, const char delim, std::vector<std::string> &out)
{
    size_t start;
    size_t end = 0;
 
    while ((start = str.find_first_not_of(delim, end)) != std::string::npos)
    {
        end = str.find(delim, start);
        out.push_back(str.substr(start, end - start));
    }
}

void Usage()
{
	printf("[%s] - FritzBox-Anrufmonitor %s %s\n\n", FCMNAME, FCMVERSION, FCMCOPYRIGHT);;
	printf("\t\tUSAGE:\t%s\n", FCMNAME);
	printf("\t\t\t-c\t\t\tget callerlist (FRITZ!Box_Anrufliste.csv)\n");
	printf("\t\t\t-h\t\t\tshow help\n");
	printf("\t\t\t-q\t\t\tsend query to FRITZ!Box\n");
	printf("\t\t\t-m\t\t\tsend message to BOXIP_1\n");
	printf("\t\t\t-s\t\t\tget smart Home infos\n");
	printf("\t\t\t-t [phonenumber] [MSN]\ttest backward search\n");
}

int main(int argc, char *argv[])
{
	CFCM * cfcm = CFCM::getInstance();
	cfcm->run(argc,argv);
}

int CFCM::run(int argc, char *argv[])
{
	printf("\n[%s] - NI FRITZ!Box-Anrufmonitor %s - %s\n", FCMNAME, FCMVERSION, FCMCOPYRIGHT);

	if(strlen(msnnum[0].msn)==0)
		printf("[%s] - Listening to all MSN's\n", FCMNAME);
	else {
		for (int i=0; i < (int)(sizeof(msnnum)/sizeof(msnnum[0])); i++) {
			if(strlen(msnnum[i].msn)!=0) {
				cout << '[' << FCMNAME << "] - Listening to MSN " << msnnum[i].msn << 
				(strlen(msnnum[i].msnName)!=0 ? " (" : "") <<
				(strlen(msnnum[i].msnName)!=0 ? msnnum[i].msnName : "") <<
				(strlen(msnnum[i].msnName)!=0 ? ")" : "") << endl;
			}
		}
	}

	switch (argc)
	{
		case 1:
			if(searchmode || !conf["DECTBOXIP"].empty())
				start_loop();
			FritzCall();
			
			return 0;
		case 2:
			if (strstr(argv[1], "-h"))
			{
				Usage();
				break;
			}
			else if (strstr(argv[1], "-b"))
			{
				switch(fork())
				{
					case 0:
						if(searchmode || !conf["DECTBOXIP"].empty())
							start_loop();
						FritzCall();
						break;

					case -1:
						printf("[%s] - Aborted!\n", FCMNAME);
						return -1;
					default:
					      exit(0);
				}
			}
			else if (strstr(argv[1], "-c"))
			{
				printf("[%s] - get FRITZ!Box_Anrufliste.csv from FritzBox\n", FCMNAME);

				if(!cconnect->get_login(conf["PASSWD"].c_str(), conf["USER"].c_str())) {
					exit(1);
				}

				//cconnect->send_refresh(cconnect->sid);
				cconnect->get_callerlist(cconnect->getSid(),conf["CALLERLIST_FILE"].c_str());
				cconnect->send_logout(cconnect->getSid());
				exit(0);
			}
			else if (strstr(argv[1], "-q"))
			{
				printf("[%s] - %s send query 2 FritzBox\n", FCMNAME, cconnect->timestamp().c_str());

				if(!cconnect->get_login(conf["PASSWD"].c_str(), conf["USER"].c_str())) {
					exit(1);
				}

				cconnect->send_TAMquery(conf["AD_FLAGFILE"].c_str(),cconnect->getSid(),conf["SEARCH_QUERY"].c_str());

				exit(0);
			}
			else if (strstr(argv[1], "-m"))
			{
				cconnect->get2box(boxnum[0].BoxIP, 80, "FritzCallMonitor Testmessage", boxnum[0].logon, conf["MSGTYPE"].c_str(), msgtimeout);
				return 0;
			}
			else if (strstr(argv[1], "-s"))
			{
				printf("[%s] - get smart Home infos from FritzBox\n", FCMNAME);

				cconnect->setFritzAdr(conf["DECTBOXIP"].c_str());

				if(!cconnect->get_login(conf["DECTPASSWD"].c_str(),conf["DECTUSER"].c_str())) {
					cconnect->setFritzAdr(conf["FRITZBOXIP"].c_str());
					exit(1);
				}

				// fill vector with device infos
				cconnect->smartHome(cconnect->getSid(),"getdevicelistinfos");

				cconnect->checkdevice(wp,dp);
				// delete device vector
				cconnect->cleardevice();

				cconnect->setFritzAdr(conf["FRITZBOXIP"].c_str());
				exit(0);
			}
			else
			{
				Usage();
				exit(1);
			}
		case 4:
			if (strstr(argv[1], "-t"))
			{
				printf("[%s] - serarch for %s\n", FCMNAME, argv[2]);
				strcpy(CallFrom, argv[2]);
				strcpy(CallTo, argv[3]);
				search(CallFrom);
				return 0;
			}
		default:
			Usage();
			exit(1);
	}
	return(0);
}

 
