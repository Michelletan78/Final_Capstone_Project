# A. R code for preprocessing #

#load packages needed
suppressPackageStartupMessages(require(tm))
suppressPackageStartupMessages(require(rJava))
suppressPackageStartupMessages(require(RWeka))
suppressPackageStartupMessages(require(corpora))
suppressPackageStartupMessages(require(dplyr))
suppressPackageStartupMessages(require(wordcloud))
suppressPackageStartupMessages(require(grid))

##load text document one file at a time
setwd ("C:/Users/Cho Seng Mong/Desktop/MDECDSC/Github/Final_Capstone_Project")
con1 <- file("./final/en_US/en_US.twitter.txt", open = "rb")
twitter <- readLines(con1, skipNul = TRUE, encoding="UTF-8")
close(con1)

con2 <- file("./final/en_US/en_US.news.txt", open = "rb")
news <- readLines(con2, skipNul = TRUE, encoding="UTF-8")
close(con2)

con3 <- file("./final/en_US/en_US.blogs.txt", open = "rb")
blogs <- readLines(con3, skipNul = TRUE, encoding="UTF-8")
close(con3)

#count length of lines and identify the longest lines in each file
twitterNlines <- length(twitter)
twitterlength <- nchar(twitter)
twitterWordCount <- sum(twitterlength)
twitterlongest <- max(twitterlength)

newsNlines <- length(news)
newslength <- nchar(news)
newsWordCount <- sum(newslength)
newslongest <- max(newslength)

blogNlines <- length(blogs)
bloglength <- nchar(blogs)
blogWordCount <- sum(bloglength)
bloglongest <- max(bloglength)

# B. R code for sampling #
# define the function to sample data with specified portions from each file
sampletext <- function(textbody, portion) {
  taking <- sample(1:length(textbody), length(textbody)*portion)
  Sampletext <- textbody[taking]
  Sampletext
}

# sampling text files 
set.seed(65364)
portion <- 1/50
SampleTwitter_02 <- sampletext(twitter, portion)
SampleBlog_02 <- sampletext(blogs, portion)
SampleNews_02 <- sampletext(news, portion)

# combine sampled texts into one variable
SampleAll_02 <- c(SampleBlog_02, SampleNews_02, SampleTwitter_02)

# write sampled texts into text files for further analysis 
writeLines(SampleTwitter_02, "./sample/en_US_twitter_sample.txt")
writeLines(SampleBlog_02, "./sample/en_US_blogs_sample.txt")
writeLines(SampleNews_02, "./sample/en_US_news_sample.txt")
writeLines(SampleAll_02, "./sampleall/en_US_all_sample.txt")

# C. R code for overviewing word distribution in three files #
# load sample texts in three seperate text documents
textsample <- VCorpus(DirSource("./sample", encoding = "UTF-8"))

# Define tokenizing function
tokenizing <- function (textcp) {
  textcp <- tm_map(textcp, content_transformer(tolower))
  textcp <- tm_map(textcp, stripWhitespace)
  textcp <- tm_map(textcp, removePunctuation)
  textcp <- tm_map(textcp, removeNumbers)
  profanity <- c("shit", "piss", "fuck", "cunt", "cocksucker", "motherfucker", "tits")
  textcp <- tm_map(textcp, removeWords, profanity)
  textcp
}

# tokenizing the sample text in three seperate documents
textsample.tk <- tokenizing(textsample)

# calculating the TermDocumentMatrix from the sample text in three seperate documents
tdm <- TermDocumentMatrix(textsample.tk)

# formating term frequency summary of each document.
tdm.m <- as.matrix(tdm)
termSummary <- cbind(tdm.m, rowSums(tdm.m))
colnames(termSummary)[4] <- "CountSum"
termSummary <- as.data.frame(termSummary)
termSummary <- termSummary[order(-termSummary$CountSum),]
termList <- row.names(termSummary)

UniqueTermCounts <- termSummary$CountSum

# D. R code for N-Gram analysis #
# load all sample text in one text document
textallsample <- VCorpus(DirSource("./sampleall", encoding = "UTF-8"))

# tokenizing sampled text 
textallsample <- tokenizing(textallsample)

# Define function to make N grams
tdm_Ngram <- function (textcp, n) {
  NgramTokenizer <- function(x) {RWeka::NGramTokenizer(x, RWeka::Weka_control(min = n, max = n))}
  tdm_ngram <- TermDocumentMatrix(textcp, control = list(tokenizer = NgramTokenizer))
  tdm_ngram
}

# Define function to extract the N grams and sort
ngram_sorted_df <- function (tdm_ngram) {
  tdm_ngram_m <- as.matrix(tdm_ngram)
  tdm_ngram_df <- as.data.frame(tdm_ngram_m)
  colnames(tdm_ngram_df) <- "Count"
  tdm_ngram_df <- tdm_ngram_df[order(-tdm_ngram_df$Count), , drop = FALSE]
  tdm_ngram_df
}

# Calculate N-Grams
tdm_1gram <- tdm_Ngram(textallsample, 1)

tdm_2gram <- tdm_Ngram(textallsample, 2)

tdm_3gram <- tdm_Ngram(textallsample, 3)

tdm_4gram <- tdm_Ngram(textallsample, 4)


# Extract term-count tables from N-Grams and sort 
tdm_1gram_df <- ngram_sorted_df(tdm_1gram)

tdm_2gram_df <- ngram_sorted_df(tdm_2gram)

tdm_3gram_df <- ngram_sorted_df(tdm_3gram)

tdm_4gram_df <- ngram_sorted_df(tdm_4gram)

saveRDS(tdm_1gram_df,"fDF1.RData")
saveRDS(tdm_2gram_df,"fDF2.RData")
saveRDS(tdm_3gram_df,"fDF3.RData")
saveRDS(tdm_4gram_df,"fDF4.RData")

# organize top ten terms in different N-Grams into data frame
TenTerms <- data.frame(row.names(tdm_1gram_df)[1:10],
                       row.names(tdm_2gram_df)[1:10],
                       row.names(tdm_3gram_df)[1:10],
                       row.names(tdm_4gram_df)[1:10])
colnames(TenTerms) = c("Unigram", "Bigram", "Trigram", "Qudragram")




# define function to calculate coverage
coverage <- function(tdm_ngram_df, percentage) {
  mincoverage <- min(which(cumsum(tdm_ngram_df)/sum(tdm_ngram_df) > percentage))
  mincoverage
}

# Calculate coverage based on each N-Gram and portions covered
cover_50_4gram <- coverage(tdm_4gram_df, 0.5)
cover_90_4gram <- coverage(tdm_4gram_df, 0.9)
cover_99_4gram <- coverage(tdm_4gram_df, 0.99)

cover_50_3gram <- coverage(tdm_3gram_df, 0.5)
cover_90_3gram <- coverage(tdm_3gram_df, 0.9)
cover_99_3gram <- coverage(tdm_3gram_df, 0.99)

cover_50_2gram <- coverage(tdm_2gram_df, 0.5)
cover_90_2gram <- coverage(tdm_2gram_df, 0.9)
cover_99_2gram <- coverage(tdm_2gram_df, 0.99)

cover_50_1gram <- coverage(tdm_1gram_df, 0.5)
cover_90_1gram <- coverage(tdm_1gram_df, 0.9)
cover_99_1gram <- coverage(tdm_1gram_df, 0.99)

coveragetable <- data.frame(c(cover_50_1gram, cover_90_1gram, cover_99_1gram),
                            c(cover_50_2gram, cover_90_2gram, cover_99_2gram),
                            c(cover_50_3gram, cover_90_3gram, cover_99_3gram),
                            c(cover_50_4gram, cover_90_4gram, cover_99_4gram), 
                            row.names = c("50%", "90%", "99%"))

colnames(coveragetable) = c("Unigram", "Bigram", "Trigram", "Qudragram")

# E. R code for plotting figures and printing tables #
# plot histogram of the word distribution 

histallplot <- function (x, main) {
  histplot <- hist(x, main = main, xlab = "Count of Word Appearances" , ylab = "Frequency" )
  histplot
}

histAll <- histallplot(UniqueTermCounts, "(a) All words")
hist_wo_100 <- histallplot(UniqueTermCounts[101:length(UniqueTermCounts)], "(b) all except words ranked top 100" )
hist_wo_1000 <- histallplot(UniqueTermCounts[1001:length(UniqueTermCounts)], "(c) all except words ranked top 1000")
hist_wo_10000 <- histallplot(UniqueTermCounts[10001:length(UniqueTermCounts)], "(d) all except words ranked top 10000")
# plot barplot of the top 10 terms in each text document
barplottop10 <- function(x, main) {
  barplottop10 <- barplot(x, main = main, names.arg = termList[1:10], las = 2, horiz = TRUE, xlab = "Counts of Word Apperances", xlim = c(0, 40000))
}
bar_Top10_blogs <- barplottop10(termSummary$en_US_blogs_sample.txt[1:10], "(a) Blogs")
bar_Top10_news <- barplottop10(termSummary$en_US_news_sample.txt[1:10], "(b) News")
bar_Top10_twitter <-barplottop10(termSummary$en_US_twitter_sample.txt[1:10], "(c) Tweets")
# plotting wordclouds of first 100 term(s) in each document
words <- rownames(termSummary)
plotWCblogs <- wordcloud(words[1:200], termSummary$en_US_blogs_sample.txt[1:200], colors = "steelblue", main = "(a) Blogs")
plotWCnews <- wordcloud(words[1:200], termSummary$en_US_news_sample.txt[1:200], colors = "steelblue", main = "(b) News")
plotWCtwitter <- wordcloud(words[1:200], termSummary$en_US_twitter_sample.txt[1:200], colors = "steelblue", main = "(c) Tweets")
# histograms of top 100 terms in different N-Grams
histNgramplot <- function (x, main) {
  histplot <- hist(x, main = main, xlab = "Count of Word/Phrase Appearances" , ylab = "Frequency" )
  histplot
}

hist1gram <- histNgramplot(tdm_1gram_df$Count[1:100], "(a) Unigram")
hist2gram <- histNgramplot(tdm_2gram_df$Count[1:100], "(b) Bigram")
hist3gram <- histNgramplot(tdm_3gram_df$Count[1:100], "(c) Trigram")
hist4gram <- histNgramplot(tdm_4gram_df$Count[1:100], "(d) Quadragram")
#print out table 2
print(TenTerms)
# print out table 3
print(coveragetable)

