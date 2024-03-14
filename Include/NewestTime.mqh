//--- defines
#define TokyoShift   -32400                           // always 9h
#define NYShift      18000                            // winter 5h : NYTime + offset = GMT
#define LondonShift  0                                // winter London offset
#define SidneyShift  -39600                           // winter Sidney offset
#define FfmShift     -3600                            // winter Frankfurt offset
#define MoskwaShift  -10800                           // winter Moscow offset
#define FxOPEN       61200                            // = NY 17:00 = 17*3600
#define FxCLOSE      61200                            // = NY 17:00 = 17*3600
#define WeekInSec    604800                           // 60sec*60min*24h*7d = 604800 => 1 Week

#define  TOSTR(A) #A+":"+(string)(A)+"  "             // Print (TOSTR(hGMT)); => hGMT:22 (s.b.)  
string _WkDy[] =                                      // week days
  {
   "Su.",
   "Mo.",
   "Tu.",
   "We.",
   "Th.",
   "Fr.",
   "Sa.",
   "Su."
  };

#define  DoWi(t) ((int)(((t-259200)%604800)/86400))      // (int)Day of Week Su=0,Mo=1,...
#define  DoWs(t) (_WkDy[DoWi(t)])                        // Day of Week as: Su., Mo., Tu., ....
#define  SoD(t) ((int)((t)%86400))                       // Seconds of Day
#define  SoW(t) ((int)((t-259200)%604800))               // Seconds of Week
#define  MoH(t) (int(((t)%3600)/60))                     // Minute of Hour 
#define  MoD(t) ((int)(((t)%86400)/60))                  // Minute of Day 00:00=(int)0 .. 23:59=1439
#define  ToD(t) ((t)%86400)                              // Time of Day in Sec (datetime) 86400=24*60*60
#define  HoW(t) (DoWi(t)*24+HoD(t))                      // Hour of Week 0..7*24 = 0..168 0..5*24 = 0..120
#define  HoD(t) ((int)(((t)%86400)/3600))                // Hour of Day 2018.02.03 17:55:56 => (int) 17
#define  rndHoD(t) ((int)((((t)%86400)+1800)/3600))%24   // rounded Hour of Day 2018.02.03 17:55:56 => (int) 18
#define  rndHoT(t) ((t+1800)-((t+1800)%3600))            // rounded Hour of Time 2018.02.03 17:55:56 => (datetime) 2018.02.03 18:00:00
#define  BoD(t) ((t)-((t)%86400))                        // Begin of day 17.5 12:54 => 17.5. 00:00:00
#define  BoW(t) ((t)-((t-172800)%604800 - 86400))        // Begin of Week.. Su 00:00:00: 604800=168h=7*24; 172800=35.5h; 86400=24h

MqlDateTime tΤ; // hidden auxiliary variable: the Τ is a Greek charackt, so virtually no danger
int DoY(const datetime t) {TimeToStruct(t,tΤ); return(tΤ.day_of_year); } // TimeDayOfYear:    1..365(366) 366/3=122*24=2928 366/4=91.5*24=2196
int MoY(const datetime t) {TimeToStruct(t,tΤ); return(tΤ.mon); }        // TimeMonthOfYear:  1..12
int YoY(const datetime t) {TimeToStruct(t,tΤ); return(tΤ.year); }
int WoY(datetime t) //Su=newWeek Week of Year = nWeek(t)-nWeeks(1.1.) CalOneWeek:604800, Su.22:00-Su.22:00 = 7*24*60*60 = 604800
  {
   return(int((t-259200) / 604800) - int((t-172800 - DoY(t)*86400) / 604800) + 1); // calculation acc. to USA
  }

