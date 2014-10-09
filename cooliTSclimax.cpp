//arm-cx2450x-linux-gnueabi-g++ -o cooliTSclimax -Wall cooliTSclimax.cpp -Wall -Wextra -Wshadow -Werror -L$PREFIX/lib -lavformat -lavcodec -lavutil -I$PREFIX/include -D__STDC_CONSTANT_MACROS -L$PREFIX/lib -lfreetype -lz -lxml2 -liconv -lpthread
//arm-pnx8400-linux-uclibcgnueabi-g++ -o cooliTSclimax -Wall cooliTSclimax.cpp -Wall -Wextra -Wshadow -Werror -L$PREFIX/lib -lavformat -lavcodec -lavutil -I$PREFIX/include -D__STDC_CONSTANT_MACROS -L$PREFIX/lib -lfreetype -lz -lxml2 -liconv -lpthread

#define _FILE_OFFSET_BITS 64

#include <iostream>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <libgen.h>

#ifdef __cplusplus
extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/avutil.h>
}
#endif
struct movieinfo
{
	std::string filename;
	std::string filetitel;
	std::string path;
	std::string  pidname[11];
	unsigned int codecID[11];
	unsigned int vpid;
	int vtype;
	unsigned int apid[11];
	unsigned int apidnumber;
	unsigned int duration;
};

bool parsets(struct movieinfo *mi)
{

	static AVInputFormat *iformat = NULL;
	AVFormatContext *ic = NULL;
	avcodec_register_all();
	av_register_all();
	if (avformat_open_input(&ic, mi->filename.c_str(), iformat, NULL) != 0) {
		printf("Couldn't open  Movie file\n");
	}
	if (ic == NULL) {
		return false;
	}

	avformat_find_stream_info(ic, NULL);
#if 0 //debug
	av_dump_format(ic, 0, mi->filename.c_str(), 0);
#endif
	mi->duration = 1000 * (ic->duration / AV_TIME_BASE);
	unsigned int i = 0;
	for (i=0; i < ic->nb_streams; i++) {
		AVStream *st = ic->streams[i];

		AVCodecContext *codec	= st->codec;
		avcodec_find_decoder(codec->codec_id);
		if (st->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
			mi->vpid=st->id;
			switch (codec->codec_id) {
			case CODEC_ID_MPEG2VIDEO:
			case CODEC_ID_MPEG1VIDEO:
				mi->vtype = 0;
				break;
			case CODEC_ID_MPEG4:
			case CODEC_ID_H264:
			case CODEC_ID_VC1:
				mi->vtype = 1;
				break;
			default:
				mi->vtype = -1;
				break;
			}

		} else if (codec->codec_type == AVMEDIA_TYPE_AUDIO ) {
			mi->apid[(mi->apidnumber)] = st->id;
			AVDictionaryEntry *lang = av_dict_get(st->metadata, "language", NULL, 0);
			if(lang)
				mi->pidname[mi->apidnumber] =  lang->value;
			else
				mi->pidname[mi->apidnumber] = "UNK";

			switch (codec->codec_id) {
			case CODEC_ID_AC3:
			case CODEC_ID_EAC3:
				mi->codecID[mi->apidnumber] = 1;// AC3
				break;
			case CODEC_ID_MP2:
				mi->codecID[mi->apidnumber] = 0;// MP2
				break;
			case CODEC_ID_MP3:
				mi->codecID[mi->apidnumber] = 4;// MP3
				break;
			case CODEC_ID_AAC:
				mi->codecID[mi->apidnumber] = 5;// AAC
				break;
			case CODEC_ID_DTS:
				mi->codecID[mi->apidnumber] = 6;// DTS
				break;
			case CODEC_ID_MLP:
				mi->codecID[mi->apidnumber] = 7;// MLP
				break;
			default:
				mi->codecID[mi->apidnumber] = codec->codec_id;
				break;
			}
			mi->apidnumber++;
		}
	}
	return true;
}

int tspatch(struct movieinfo *mi)
{
	unsigned char buf[8]={0};
	unsigned char *p = NULL;
	FILE *tsp=NULL;
	tsp = fopen (mi->filename.c_str(), "r+b");
	if (fseek (tsp, 0xb4, SEEK_SET) < 0) {
		fclose (tsp);
		return -1;
	}
	int l=fread(buf, sizeof(unsigned char), sizeof(buf)/sizeof(*buf), tsp);

	if ( l!=8 ) {
		fclose (tsp);
		return -1;
	}

	p=(unsigned char *)&mi->duration;
	memcpy(buf,p,4);
	if (fseek (tsp, 0xb4, SEEK_SET) < 0) {
		fclose (tsp);
		return -1;
	}
	buf[4]=0xbc;
	buf[5]=0;
	buf[6]=0;
	buf[7]=0;
	fwrite(buf, sizeof(unsigned char), sizeof(buf)/sizeof(*buf), tsp);
	fclose (tsp);
	return 1;
}

void writeXML(struct movieinfo *mi)
{
	struct stat buf;
	if (stat((mi->filetitel+".xml").c_str(),&buf) != 0) {

		unsigned int i = 0;
		int len =0 ;
		char tmpbuf[4096] = {0};
		len = snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"<neutrino commandversion=\"1\">\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"	<record command=\"record\">\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<channelname>Archiv</channelname>\n");/**channame**/
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<epgtitle>%s</epgtitle>\n",mi->filetitel.c_str());/**epg titel**/
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<id>0</id>\n");/**  id**/
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<info1></info1>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<info2></info2>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<epgid></epgid>\n");/** epg id**/
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<mode>1</mode>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<videopid>%u</videopid>\n",mi->vpid);/** VPID**/
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<videotype>%01d</videotype>\n",mi->vtype);
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<audiopids>\n");
		for (i=0; i<mi->apidnumber; i++) {
				switch(mi->codecID[i])
				{
					case 1: /*AC3,EAC3*/
						
						mi->pidname[i] += " (AC3)";
						break;
					case 0: /*MP2*/
						mi->pidname[i] += " (MP2)";
						break;
					case 4: /*MP3*/
						mi->pidname[i] += " (MP3)";
						break;
					case 5: /*AAC*/
						mi->pidname[i] += " (AAC)";
						break;
					case 6: /*DTS*/
						mi->pidname[i] += " (DTS)";
						break;
					case 7: /*MLP*/
						mi->pidname[i] += " (MLP)";
						break;
					default:
						break;
				}

			len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"			<audio pid=\"%u\" audiotype=\"%u\" selected=\"%i\" name=\"%s\"/>\n",mi->apid[i],mi->codecID[i], i==0?1:0, mi->pidname[i].c_str());
		}
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		</audiopids>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<vtxtpid>0</vtxtpid>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<genremajor>0</genremajor>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<genreminor>0</genreminor>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<seriename></seriename>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<length>0</length>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<productioncountry></productioncountry>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<productiondate>0</productiondate>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<qualitiy>0</qualitiy>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<parentallockage>0</parentallockage>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<dateoflastplay>%llu</dateoflastplay>\n",(long long unsigned int) time(NULL));
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		<bookmark>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"			<bookmarkstart>0</bookmarkstart>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"			<bookmarkend>0</bookmarkend>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"			<bookmarklast>0</bookmarklast>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"			<bookmarkuser bookmarkuserpos=\"0\" bookmarkusertype=\"0\" bookmarkusername=""/>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"		</bookmark>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"	</record>\n");
		len += snprintf(tmpbuf+len,sizeof(tmpbuf)-len,"</neutrino>\n");
		FILE * fp = fopen((mi->path.c_str()+mi->filetitel+".xml").c_str(), "w");
		if (fp)
		{
			fprintf(fp,"%s", tmpbuf);
			fclose(fp);
			printf("Create %s file\n",(mi->path.c_str()+mi->filetitel+".xml").c_str());
		}
	}

}

int main(int argc, char *argv[]) {
	if (argc != 2)
	{
		printf("USE:cooliTSclimax <file.ts>\n");
		printf("cooliTSclimax Version 0.003\n");
		return 1;
	}

	struct movieinfo mi;
	mi.filename=argv[1];
	if (strncmp((mi.filename.substr(mi.filename.length()-3,mi.filename.length())).c_str(),const_cast<char *>(".ts"),3)) {
		printf("No TS FILE\n");
		return 1;
	}
	struct stat buf;
	if (stat(mi.filename.c_str(),&buf) == 0) {
		char *prog = basename (argv[1]);
		char *dirpath=dirname(argv[1]);
		mi.path=dirpath;
		mi.path+="/";
		mi.filetitel=prog;
		printf("File:%s\n",mi.filetitel.c_str());
		mi.filetitel= mi.filetitel.substr(0,mi.filetitel.length()-3).c_str();
		mi.vpid=0;
		memset(mi.apid,0,10);
		mi.apidnumber=0;
		mi.vtype=-1;
		parsets(&mi);
		writeXML(&mi);
		if(tspatch(&mi)!=-1){
			printf("File %s patched\n",mi.filename.c_str());
		}
	}
	else
	{
		printf("File \"%s\" not found\n",mi.filename.c_str());
	}
	return 0;
}
