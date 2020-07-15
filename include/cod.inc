#if defined _cod_included
  #endinput
#endif
#define _cod_included

#define COD_CONTINUE 0
#define COD_STOP 4

native cod_registerClass(const String:name[], const String:description[], const String:weapons[], intelligence, health, damage, resistance, stamina);
native cod_registerItem(const String:name[], const String:description[], minVal, maxVal);