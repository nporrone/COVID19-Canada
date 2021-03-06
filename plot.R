library(ggplot2);theme_set(theme_bw())
library(directlabels)
library(tidyverse)
library(ggrepel)
library(ggforce)
library(gridExtra)
library(colorspace)
library(grid)
library(zoo)

## use url link?
ddcapacity <- (read_csv("capacity.csv")
#	%>% mutate(Province = factor(Province)
#	      , Province = factor(Province,levels = c("BC","AB","ON","QC","SK", "MB","NB","NS","PEI","NL","YT","NT","NU")
#			, labels = c("British Columbia", "Alberta", "Ontario", "Quebec", "Saskatchewan", "Manitoba", "New Brunswick","Nova Scotia", "Prince Edward Island", "Newfoundland", "Yukon", "Northwest Territories","Nunavut")))
)

label_dat <- (ddclean
    %>% group_by(Province)
    %>% filter(Date == max(Date))
    %>% mutate(lab_positives = paste0(Province,":",cumConfirmations)
               , lab_total = paste0(Province,":",bestTotal)
               , lab_newConfirmations = paste0(Province, ":",newConfirmations)
					, lab_death = paste0("Death",":",deceased)
					, lab_hosp = paste0("Hosp",":",Hospitalization)
					, lab_icu = paste0("ICU",":",ICU)
					, lab_vent = paste0("Vent",":",Ventilator)
					, lab_prop = paste0(Province,":",prop,"%")
               , Date = Date + 5
					)
	 %>% ungroup()
)

## Working on today code

ddtoday <- (ddclean
	%>% filter(Date == max(Date))
	%>% select(Date, Province, newTests, newConfirmations, prop)
)

print(didnotupdate <- (ddtoday
	%>% filter(is.na(newTests))
)
)

ddtoday <- (ddtoday 
	%>% filter(newTests>0)
	## Temp hack to today's labels
#	%>% mutate(Province = ifelse(Province == "NL", "NL,NB,NS,PEI", Province)
#		, Province = ifelse(Province %in% c("NS","NB","PEI"), "", Province)
#		, Province = ifelse(Province == "PEI","PEI,NL,NB", Province)
#	)
	%>% ungroup()
	%>% arrange(newTests)
)

print(ddtoday)


ddslopes <- data.frame(x=c(1,1,1,1)
	, y = c(0.02,0.05,0.1,0.15)
	, xend = c(2000/0.02, 2000/0.05, 2000/0.1, 2000/0.15)
	, yend = c(2000,2000,2000,2000)
)

print(ddslopes)

ggtoday <- (ggplot(ddtoday, aes(x=newTests))
	+ geom_point(aes(y=newConfirmations,color=prop))
	+ geom_segment(data=ddslopes,aes(x=x,y=y,xend=xend,yend=yend,color=y))
	+ geom_text(data=ddslopes,aes(x=x,y=y,label=y,color=y),hjust=0.5)
	+ geom_text(aes(y=newConfirmations,label=Province),vjust=-0.5,hjust=-0.001)
	+ xlim(c(1,7000))
	+ ylim(c(0.01,800))
	+ scale_x_log10(breaks=c(1,ddtoday$newTests[c(1,4,5,6,8,9,10,11,12,13)]))
	+ scale_y_log10(breaks=c(0.001,ddtoday$newConfirmations))
	+ theme(axis.text.x = element_text(angle = 65,vjust=0.65,hjust=1)
		, panel.grid.minor = element_blank())
	+  scale_colour_gradient(low = "blue", high = "red", na.value = NA)
	+ xlab("New Tests")
	+ ylab("New Confirmations")
)

print(ggtoday)
ggsave(ggtoday, filename="ggtoday.png", width = 9, height=5) 

### Quebec

QC <- (ddclean
	%>% filter(Province == "QC")
	%>% filter(Date > as.Date("2020-04-15"))
	%>% select(Date,newConfirmations,newTests,prop)
)

ggqc <- (ggplot(QC, aes(x=newTests, y=newConfirmations,color=prop))
	+ geom_point()
	+ geom_line()
	+ scale_linetype_manual(values=c("dashed"))
	+ geom_text(aes(label=Date),color="black")
	+ geom_text(aes(x=3200,y=700,label=0.2))
	+ geom_text(aes(x=4500,y=700,label=0.15))
	+ geom_abline(slope=0.2,color="red")
	+ geom_abline(slope=0.15,color="#C10259")
	+ xlim(c(3000,6000))
	+ ylim(c(700,1000))
	+ scale_color_gradient(low="#C10259", high = "red")
)


print(ggqc)
ggsave(ggqc, filename="ggqc.png")

## FIXME:: DRY: how different are these two plots??
##  could this be done with faceting?

## for boldfacing parts of titles below,
##  could use expression('... bold(...) ...'); parse(text=...) is
##  more flexible, could be used to incorporate variables etc.

## plot(0:1,0:1,type="n")
## text(0.5,0.5,expression('zzz'~bold('abc')~'aaa'))
## text(0.1,0.1,parse(text="'zzz'~bold('abc')~'aaa'"))

## Cumulative reports 
ddcumreport <- ddclean %>% filter(cumConfirmations>0)

gg <- (ggplot(ddcumreport, aes(x=Date, y=cumConfirmations,color=Province))
        + scale_colour_discrete_qualitative()
	+ scale_y_continuous(trans="log2")
	+ scale_x_date()
	+ geom_text_repel(data=label_dat,aes(label = lab_positives)
	  , hjust = -10
	  , direction = "y"
	  , size = 3
	  # , nudge_y = 5
	  , segment.color = NA
	  , show.legend = FALSE
	  )
        + geom_line()
        + ggtitle(parse(text="'Cumulative Reported'~bold('Positive')~'Tests'"))
	+ theme(legend.position = "none", axis.title.y=element_blank()
	        , plot.title = element_text(vjust=-10,hjust=0.1,size=10))
)

print(gg)

### Cumulative tests

ddcumtest <- ddclean %>% filter(bestTotal>0)

gg2 <- (ggplot(ddcumtest, aes(x=Date, y=bestTotal,color=Province))
       + scale_colour_discrete_qualitative()
       + scale_y_continuous(trans="log2")
       + scale_x_date()
       + geom_text_repel(data=label_dat,aes(label = lab_total)
                         , hjust = -10
                         , direction = "y"
                         , size = 3
                         # , nudge_y = 5
                         , segment.color = NA
                         , show.legend = FALSE
       )
       + geom_line()
       + ggtitle(parse(text="'Cumulative Reported'~bold('Total')~'Tests'"))
       + theme(legend.position = "none", axis.title.y=element_blank()
               , plot.title = element_text(vjust=-10,hjust=0.1,size=10))
)

print(gg2)
ggcombo <- grid.arrange(gg,gg2,nrow=1)
print(ggcombo)
ggsave(plot=ggcombo,filename = "plot.png",width = 10, height = 6)

## Daily new confirmation proportion
gg3 <- (ggplot(ddclean, aes(x=Date, y=prop,color=Province))
        + scale_colour_discrete_qualitative()
        + scale_y_continuous(trans="log2")
        + scale_x_date()
        + geom_line()
        + ggtitle(parse(text="'New Reported Proportion'~bold('Positive')~'Tests'"))
        + theme(legend.position = "none", axis.title.y=element_blank()
                , plot.title = element_text(vjust=-10,hjust=0.1,size=10))
)

print(gg3)

print(gg3
	+ geom_line(aes(y=newTests), color="black")
	+ facet_wrap_paginate(~Province, nrow=1, ncol=1, page=9)
)


hosp_lab_dat <- (label_dat
	%>% select(Date, Province, Hospitalization=lab_hosp, ICU=lab_icu, Ventilator=lab_vent, Death = lab_death)
	%>% gather(key="HospType",value="labs",-Date,-Province)
	%>% mutate(Date = ifelse(Province %in% c("SK","MB","NB","NS","NL")
		, Date - 2, Date)
		, Date = as.Date(Date)
	 	, Province = factor(Province)
		, Province = factor(Province,levels = c("BC","AB","ON","QC","SK","MB","NB","NS","PEI","NL","YT","NT","NU")
		, labels = c("British Columbia", "Alberta", "Ontario", "Quebec",  "Saskatchewan", "Manitoba", "New Brunswick","Nova Scotia", "Prince Edward Island", "Newfoundland", "Yukon", "Northwest Territories","Nunavut"))) 
)

print(hosp_lab_dat,n=100)

## Hospitalization
ddhosp <- (ddclean
  %>% select(Date, Province, Hospitalization, ICU, Ventilator, Death=deceased)
  %>% gather(key="HospType",value="Count",-Date,-Province)
  %>% filter(!is.na(Count)&(Count>0))
  %>% filter(HospType != "Death")
  %>% left_join(.,ddcapacity)
  # %>% left_join(.,hosp_lab_dat)
  %>% mutate(Province = factor(Province,levels = c("BC","AB","ON","QC","SK","MB","NB","NS","PEI","NL","YT","NT","NU")
  	, , labels = c("British Columbia", "Alberta", "Ontario", "Quebec", "Saskatchewan", "Manitoba", "New Brunswick","Nova Scotia", "Prince Edward Island", "Newfoundland", "Yukon", "Northwest Territories", "Nunavut")))
)

print(ddhosp)


ddhosplab <- (ddhosp
  %>% filter(Date == as.Date(max(Date)))
  %>% select(Province,HospType,Count)
  %>% left_join(hosp_lab_dat,.)
  %>% filter(HospType != "Death")
  %>% ungroup()
  %>% filter(Province %in% c("Alberta","British Columbia","Ontario","Quebec","Saskatchewan","Manitoba","New Brunswick","Nova Scotia","Newfoundland"))
#  %>% mutate(Province = factor(Province
#  	,	levels = c("BC","AB","ON","QC","SK","MB","NB","NS","PEI","NL","YU","NWT","NU")
#  	, labels = c("British Columbia", "Alberta", "Ontario", "Quebec", "Saskatchewan", "Manitoba", "New Brunswick","Nova Scotia", "Prince Edward Island", "Newfoundland", "Yukon", "Northwest Territories", "Nunavut")
#	)
#  )
)

print(ddhosplab)

quit()
gghosp <- (ggplot(ddhosp, aes(x=Date, y=Count,color=HospType))
		 + geom_text_repel(data=ddhosplab,aes(x=Date,label = labs)
                          , hjust = -20
		                      , vjust= 3.5
                          , direction = "y"
                          , size = 3
                          # , nudge_y = 5
                          , segment.color = NA
                          , show.legend = FALSE
        )
#		+ geom_dl(data=ddhosplab,aes(x=Date,label = labs), method=list(cex=1,'last.bumpup'),size=4)
       + geom_line()
       + geom_point(size=0.5)
		 + geom_hline(aes(yintercept=Current), color="red",linetype=2)
       + theme(legend.position = "bottom"
               , axis.text.x = element_text(angle = 45,vjust=0.5)
               , plot.title = element_text(vjust=0,hjust=0.1,size=10)
					, strip.background = element_blank())
       + facet_wrap(~Province,nrow=3, scale="free")
       + scale_colour_manual(values=c("black","red","blue"))
		 + scale_y_log10(breaks=c(1,5,10,30,50,100,200,300,600,800))
		 + ylab("Prevalence (Current Occupancy)")
#		 + xlim(c(as.Date(min(ddhosp$Date)),as.Date(max(ddhosp$Date)+8)))
)

print(gghosp)
ggsave(plot=gghosp,filename = "plothosp.png",width = 12, height = 9)
