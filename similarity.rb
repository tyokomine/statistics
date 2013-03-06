# coding: UTF-8
require 'MeCab'

#文章から記号、助詞、助動詞を省いた単語の配列を返す関数
def return_word(s)
  c = MeCab::Tagger.new(ARGV.join(""))
  word = []
  node = c.parseToNode(s)
  begin
    node = node.next
    if /^記号/ !~ node.feature.force_encoding("UTF-8") && /^助詞/ !~ node.feature.force_encoding("UTF-8") && /^助動詞/ !~ node.feature.force_encoding("UTF-8")
      word << node.surface.force_encoding('UTF-8')
    end
  end until node.next.feature.include?("BOS/EOS")
  return word
end

#与えられた２つの文のcos類似度を返す関数
def cos_similarity(s1,s2)
  word1 = return_word(s1)
  word2 = return_word(s2)
  ue = 0
  x = 0
  y = 0
  @tf_idf.each do |k,v|
    if word1.include?(k) && word2.include?(k)
      ue += v*v
      x += v*v
      y += v*v
    elsif word1.include?(k)
      x += v*v
    elsif word2.include?(k)
      y += v*v
    end
  end
  cos_s = ue/(Math.sqrt(x)+Math.sqrt(y))
  return cos_s
end

#与えられた２つの文の相関係数を返す関数
def correlation_similarity(s1,s2)
  word1 = return_word(s1)
  word2 = return_word(s2)
  ue = 0
  x = 0
  y = 0
  cnt = 0
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



