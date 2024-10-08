<chart>
id=133531248013358506
symbol=EURUSD
description=Euro vs US Dollar
period_type=0
period_size=10
digits=5
tick_size=0.000000
position_time=0
scale_fix=0
scale_fixed_min=1.080200
scale_fixed_max=1.089000
scale_fix11=0
scale_bar=0
scale_bar_val=1.000000
scale=16
mode=1
fore=0
grid=1
volume=0
scroll=1
shift=0
shift_size=19.933278
fixed_pos=0.000000
ticker=1
ohlc=1
one_click=0
one_click_btn=1
bidline=1
askline=0
lastline=0
days=0
descriptions=0
tradelines=1
tradehistory=1
window_left=0
window_top=0
window_right=0
window_bottom=0
window_type=3
floating=0
floating_left=0
floating_top=0
floating_right=0
floating_bottom=0
floating_type=1
floating_toolbar=1
floating_tbstate=
background_color=16777215
foreground_color=0
barup_color=10135078
bardown_color=5264367
bullcandle_color=10135078
bearcandle_color=5264367
chartline_color=8698454
volumes_color=10135078
grid_color=15920369
bidline_color=10135078
askline_color=5264367
lastline_color=15776412
stops_color=5264367
windows_total=1

<window>
height=100.000000
objects=2

<indicator>
name=Main
path=
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1
</indicator>

<indicator>
name=Custom Indicator
path=Indicators\Examples\BB.ex5
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=4
fixed_height=-1

<graph>
name=Bands(20) Middle
draw=1
style=0
width=1
color=11186720
</graph>

<graph>
name=Bands(20) Upper
draw=1
style=0
width=1
color=11186720
</graph>

<graph>
name=Bands(20) Lower
draw=1
style=0
width=1
color=11186720
</graph>
<inputs>
InpBandsPeriod=20
InpBandsShift=0
InpBandsDeviations=2.0
</inputs>
</indicator>

<indicator>
name=Custom Indicator
path=Indicators\Free Indicators\Keltner_Channel.ex5
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=4
fixed_height=-1

<graph>
name=Upper Keltner
draw=1
style=0
width=1
shift=1
color=42495
</graph>

<graph>
name=Middle Keltner
draw=1
style=0
width=1
shift=1
color=-1
</graph>

<graph>
name=Lower Keltner
draw=1
style=0
width=1
shift=1
color=42495
</graph>
<inputs>
InpEMAPeriod=20
InpATRPeriod=20
InpATRFactor=1.5
InpShowLabel=false
</inputs>
</indicator>
<object>
type=31
name=autotrade #150066014327 buy 0.1 EURUSD at 1.08239, EURUSD
hidden=1
descr=python script
color=11296515
selectable=0
date1=1708657371
value1=1.082390
</object>

<object>
type=31
name=autotrade #150066015133 buy 0.1 EURUSD at 1.08246, EURUSD
hidden=1
descr=python script
color=11296515
selectable=0
date1=1708657429
value1=1.082460
</object>

</window>
</chart>