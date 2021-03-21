/*
 * FritzCallMonitor.h 
 */
#ifndef __FritzCallMonitor_h__
#define __FritzCallMonitor_h__

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <vector>
#include <map>

#include "connect.h"

#define FCMNAME "FCM"
#define FCMVERSION "V5.2"
#define FCMCOPYRIGHT "2010, 2017 (c) FlatTV"

#define BUFFERSIZE 1024
#define MAXITEM 10 
#define CONFIGFILE "/var/tuxbox/config/FritzCallMonitor.cfg"

using namespace std;

class CFCM
{
	public:
		CFCM();
		~CFCM();
		static CFCM* getInstance();

		int	run(int argc, char *argv[]);

	private:
		CConnect *	cconnect;
		pthread_t	thrTimer;

		vector<string> dect;
		map<string, string> conf; // config pair
		map<string, vector<string> > dp; // DECT time and temperatur
		map<string, vector<string> > wp; // DECT week

		typedef struct {
			char	name[256];
			char	street[128];
			char	code[6];
			char	locality[128];
		} S_ADDRESS;
		S_ADDRESS address;

		typedef struct {
			char BoxIP[25];
			char logon[64];
		} S_BOXNUM;
		S_BOXNUM boxnum[4];

		typedef struct {
			char msn[32];
			char msnName[64];
		} S_MSNNUM;
		S_MSNNUM msnnum[6];

		char	CallFrom[64];
		char	CallTo[64];
		char	CallToName[64];

		int	debug, BackwardSearch, msgtimeout,easymode, phonebooks, FritzPort, SearchPort, searchmode, searchint;

		//global functions
		void	FritzCall();
		void	sendMSG(int caller_address);
		int		search(const char *searchNO);
		int		read_conf(const string& file);
		int		add_AddrBook(const char *caller);
		int		search_AddrBook(const char *caller);
		string	create_map(string& k, const string& t, string& v, map<string, vector<string> >& m);
		string	create_map(string& k, const string& t, const string& v, map<string, string>& m);
		void 	tokenize(std::string const &str, const char delim, std::vector<std::string> &out);

		//query thread
		static void*	proxy_loop(void *arg);
		void	start_loop();
		void	stop_loop();
		int	query_loop();

		vector<string> split(stringstream& str, const char& delim);
};

#endif// __FritzCallMonitor_h__
