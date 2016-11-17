require("ggplot2")
require("reshape")
require("plyr")
require("ggthemes")
require("directlabels")

times <- read.csv("out-times-beijing.csv", sep="\t", col.names=c("url", "time"))
times$url <- as.character(times$url)
final <- ddply(times,~url,summarise,mean_time_beijing=mean(time),sd_time_beijing=sd(time))

times2 <- read.csv("out-times.csv", sep="\t", col.names=c("url", "time"))
times2$url <- as.character(times2$url)
final2 <- ddply(times2,~url,summarise,mean_time_nyc=mean(time),sd_time_nyc=sd(time))

combined <- merge(final,final2,by="url")
combined$time_diff <- combined$mean_time_nyc - combined$mean_time_beijing
combined.m <- melt(combined, id.vars=c('url'), measure.vars=c('mean_time_beijing', 'mean_time_nyc'))

png('crawl-stats-comparison-parallel.png', width=600, height=800)
ggplot(combined.m) +
  geom_line(aes(x = variable, y = value, group = url)) +
  theme_tufte() +
  ylab("Load Time (ms)") + xlab("")
dev.off()

png('crawl-stats-comparison-time-diff-bar.png', width=600, height=1200)
ggplot(combined, aes(x=reorder(url, -time_diff), y=time_diff)) +
  geom_bar() +
  theme_tufte() +
  coord_flip() +
  xlab("Load Time Diff (ms)") +
  ylab("URL")
dev.off()

png('crawl-stats-comparison-scatter.png', width=600, height=600)
ggplot(combined, aes(x=mean_time_beijing, y=mean_time_nyc)) +
  geom_point() +
  theme_tufte() +
  xlab("Beijing Load Time (ms)") +
  ylab("NYC Load Time (ms)")
dev.off()

png('crawl-stats-comparison-scatter-text.png', width=600, height=600)
ggplot(combined, aes(x=mean_time_beijing, y=mean_time_nyc)) +
  geom_text(aes(label=url), size=3) +
  theme_tufte() +
  xlab("Beijing Load Time (ms)") +
  ylab("NYC Load Time (ms)")
dev.off()