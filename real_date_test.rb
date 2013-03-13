# coding: utf-8
require 'MeCab'
require 'mysql2'
require 'dbi'

@mecab = MeCab::Tagger.new

#文章から記号、助詞、助動詞を省いた単語の配列を返す関数
def return_word(s)
#  c = MeCab::Tagger.new(ARGV.join(""))
  word = []
  node = @mecab.parseToNode(s)
  begin
    node = node.next
    if /^記号/ !~ node.feature.force_encoding("UTF-8") && /^助詞/ !~ node.feature.force_encoding("UTF-8") && /^助動詞/ !~ node.feature.force_encoding("UTF-8")&& /^数/ !~ node.feature.force_encoding("UTF-8") 
      word << node.surface.force_encoding('UTF-8')
    p node.surface.force_encoding('UTF-8'),node.feature.force_encoding('UTF-8')
    end
  end until node.next.feature.include?("BOS/EOS")
  return word
end

#与えられた２つの文のcos類似度を返す関数
def cos_similarity(s1,s2)
#  word1 = return_word(s1)
#  word2 = return_word(s2)
 word1 = s1
 word2 = s2
  ue = 0
  x = 0
  y = 0
  word1.each do |w|
    v = @tf_idf[w]
    ue += v*v if word2.include?(w)
    x += v*v
  end
  word2.each do |w|
    v = @tf_idf[w]
    y += v*v
  end
  cos_s = ue/(Math.sqrt(x)+Math.sqrt(y))
  return cos_s
end

#与えられた２つの文の相関係数を返す関数
def correlation_similarity(s1,s2)
#  word1 = return_word(s1)
#  word2 = return_word(s2)
 word1 = s1
 word2 = s2
  ue = 0
  x = 0
  #平均を求める
  @tf_idf.each do |k,v|
    x += v if word1.include?(k)
    y += v if word2.include?(k)
    cnt += 1 if word1.include?(k) || word2.include?(k)
  end
  x_ = x/cnt.to_f
  y_ = y/cnt.to_f

  @tf_idf.each do |k,v|
    if word1.include?(k) && word2.include?(k)
      ue += (v-x_)*(v-y_)
      x += (v-x_)*(v-x_)
      y += (v-y_)*(v-y_)
    elsif word1.include?(k)
      ue += (v-x_)*(-y_)
      x += (v-x_)*(v-x_)
      y += y_*y_
    elsif word2.include?(k)
      ue += (-x_)*(v-y_)
      x += x_*x_
      y += (v-y_)*(v-y_)
    end
  end
  cor_s = ue/(Math.sqrt(x)+Math.sqrt(y))
  return cor_s
end

word_hash = Hash.new(Array.new)
word_array = Array.new
sentences = Array.new
row = Array.new
word_num = {}
client= Mysql2::Client.new(:host =>'localhost', :username =>  'root',:password =>  '1x60Ks4N',:database =>  'wiretap')
cnt = 0
client.query('select distinct text from tweet limit 500').each do |col|
#  puts col['text']
  word_hash[cnt] = Array.new
  word_hash[cnt] = return_word(col['text'])
  word_array += word_hash[cnt]
  sentences << word_hash[cnt]
  word_hash[cnt].each do |key|
    word_num[key] ||= 0
    word_num[key] += 1
  end
  row << col['text']
  cnt += 1
end
=begin
#sentences = [s1,s2,s3,s4,s5,s6,sentence]
sentences.each_with_index do |s,i|
  node = c.parseToNode(s)
  word_hash[i] = Array.new
  word_hash[i] = return_word(s)
  word_array += word_hash[i]
end
#p word_hash
word_num = {}

=end

puts word_num
words_num = word_array.size
p words_num
@tf_idf = {}

word_num.each do |key,value|
 @tf_idf[key] = (value/words_num.to_f) * Math.log(sentences.size/value.to_f)
end
#p @tf_idf

target_id = 4107
p row[target_id]
p "== cos similarity =="

ans = Hash.new()
s = sentences[target_id]
#sentences.each_with_index do |s,i|
  sentences.each_with_index do |s1,j|
    key = j
    if target_id == j
      ans[key] = 0
    else
      ans[key] = cos_similarity(s,s1)
    end
    #printf "s%d s%d %f \n",i+1,j+1,cos_similarity(s,s1)
  end
#end
#p ans
rank = 50
cnt = 0
#降順にソート
ans.sort{|a, b| b[1] <=> a[1]}.each do|key, value|
   p row[key]
   break if cnt > rank
   cnt += 1
  # puts "#{key}: #{value}"
end
=begin
p "== correlation similarity =="
ans2 = Hash.new()
sentences.each_with_index do |s,i|
  sentences.each_with_index do |s1,j|
#    ans[i] << cos_similarity(s,s1)
    key = (i+1).to_s+(j+1).to_s
    if i == j
      ans2[key] = 0
    else
      ans2[key] = correlation_similarity(s,s1)
    end
   # printf "s%d s%d %f \n",i+1,j+1,correlation_similarity(s,s1)
  end
end
p ans2
#降順にソート
ans2.sort{|a, b| b[1] <=> a[1]}.each do|key, value|
    puts "#{key}: #{value}"
end

=end


