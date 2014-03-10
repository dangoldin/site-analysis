require("ggplot2")
require("reshape")
require("plyr")
require("ggthemes")

setwd("/Users/danielgoldin/Dropbox/dev/web/site-js-usage")

get_type <- function (x) {
  x <- tolower(x)
  res <- "Unknown"
  if (grepl("javascript", x)) {
    res <- "JavaScript"
  } else if (grepl("css", x)) {
    res <- "CSS"
  } else if (grepl("image", x)) {
    res <- "Image"
  } else if (grepl("font", x)) {
    res <- "Font"
  } else if (grepl("html", x)) {
    res <- "HTML"
  } else if (grepl("json", x)) {
    res <- "JSON"
  } else if (grepl("octet-stream", x)) {
    res <- "Binary"
  } else if (grepl("text/plain", x)) {
    res <- "Text"
  } else if (grepl("x-shockwave-flash", x)) {
    res <- "Flash"
  }
  res
}

all_data <- read.csv("out.csv", sep="\t", col.names=c("url","type","file_url"))
uni_data <- all_data[!duplicated(all_data),]
uni_data$file_type <- sapply(uni_data$type, get_type, simplify = TRUE)
uni_data$url <- as.character(uni_data$url)

table(uni_data$file_type)

uni_data$type[uni_data$file_type == "Unknown"]

times <- read.csv("out-times.csv", sep="\t", col.names=c("url", "time"))
times$url <- as.character(times$url)

final <- ddply(times,~url,summarise,mean_time=mean(time),sd_time=sd(time))

final$num_requests <- sapply(final$url, function(u) {
  d <- uni_data[uni_data$url == u,]
  length(d$file_url)
  }, simplify=TRUE)

request_counts <- ddply(uni_data,~url + file_type,summarize,count=length(type))
request_counts_pivot <- cast(request_counts, url ~ file_type)
request_counts_pivot[is.na(request_counts_pivot)] <- 0

final <- merge(final,request_counts_pivot,by="url")

final.m <- melt(final, id.vars=c('url'), measure.vars=c('Binary','CSS','Flash','Font','HTML','Image','JavaScript','JSON','Text','Unknown'))

png("crawl-stats-times-mean.png", width=600, height=1000)
ggplot(times, aes(x = reorder(url, -time), y = time)) +
  stat_summary(fun.y = "mean", geom = "bar") +
  theme_tufte() +
  coord_flip() +
  ylab("Load Time (ms)") + xlab("URL")
dev.off()

png("crawl-stats-times-boxplot.png", width=600, height=1000)
ggplot(times, aes(x = reorder(url, -time), y = time)) +
  geom_boxplot() +
  theme_tufte() +
  coord_flip() +
  ylab("Load Time (ms)") + xlab("URL")
dev.off()

png("crawl-stats-requests-count.png", width=600, height=1000)
ggplot(final, aes(x = reorder(url, -num_requests), y = num_requests)) +
  geom_boxplot() +
  theme_tufte() +
  coord_flip() +
  ylab("# Requests") + xlab("URL")
dev.off()

png("crawl-stats-requests-vs-time.png", width=600, height=600)
ggplot(final, aes(x=num_requests, y=mean_time)) +
  geom_point() +
  theme_tufte() +
  ylab("Load Time (ms)") + xlab("# Requests")
dev.off()

png("crawl-stats-file-types-url.png", width=600, height=1000)
ggplot(final.m, aes(x = reorder(url, -value), y = value, fill = variable)) +
       geom_bar(stat = "identity") +
       theme_tufte() +
       coord_flip() +
       theme(legend.justification=c(1,1), legend.position=c(1,1))
dev.off()

png("crawl-stats-file-types-count.png", width=600, height=600)
ggplot(final.m, aes(x = variable, y = value)) +
  stat_summary(fun.y = "sum", geom = "bar") +
  theme_tufte() +
  ylab("Count") + xlab("Type")
dev.off()

png("crawl-stats-file-types-correlation.png", width=600, height=600)
qplot(x=X1, y=X2, data=melt(cor(final[5:14])), fill=value, geom="tile") +
  scale_fill_continuous(name="Correlation") +
  xlab("") + ylab("")
dev.off()

fit <- lm(mean_time ~ Binary + CSS + Flash + Font + HTML + Image + JavaScript + JSON + Text + Unknown, data=final)
summary(fit)