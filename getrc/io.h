#ifndef __IO_H__
#define __IO_H__

#include <rc_device.h>

// rc codes

#undef KEY_0
#undef KEY_EPG
#undef KEY_SAT
#undef KEY_STOP
#undef KEY_PLAY

#define KEY_0					1  
#define KEY_1			 		2   
#define KEY_2			 		3   
#define KEY_3			 		4   
#define KEY_4			 		5   
#define KEY_5			 		6   
#define KEY_6			 		7   
#define KEY_7			 		8   
#define KEY_8			 		9   
#define KEY_9					10   
#define KEY_BACKSPACE           14   
#define KEY_UP                  103   
#define KEY_LEFT                105   
#define KEY_RIGHT               106   
#define KEY_DOWN                108   
#define KEY_MUTE                113   
#define KEY_VOLUMEDOWN          114   
#define KEY_VOLUMEUP            115   
#define KEY_POWER               116   
#define KEY_HELP                138   
#define KEY_HOME                102   
#define KEY_SETUP               141   
#define KEY_PAGEUP              104   
#define KEY_PAGEDOWN            109   
#define KEY_OK           		0x160         /* in patched input.h */
#define KEY_RED          		0x18e         /* in patched input.h */
#define KEY_GREEN        		0x18f         /* in patched input.h */
#define KEY_YELLOW       		0x190         /* in patched input.h */
#define KEY_BLUE         		0x191         /* in patched input.h */

#define KEY_TVR					0x179
#define KEY_TTX					0x184
#define KEY_COOL				0x1A1
#define KEY_FAV					0x16C
#define KEY_EPG					0x16D
#define KEY_VF					0x175

#define KEY_SAT					0x17D
#define KEY_SKIPP				0x197
#define KEY_SKIPM				0x19C
#define KEY_TS					0x167
#define KEY_AUDIO				0x188
#define KEY_REW					0x0A8
#define KEY_FWD					0x09F
#define KEY_HOLD				0x077
#define KEY_REC					0x0A7
#define KEY_STOP				0x080
#define KEY_PLAY				0x0CF

int InitRC(void);
int CloseRC(void);
int RCKeyPressed(void);
int GetRCCode(char *key, int timeout);

#endif
