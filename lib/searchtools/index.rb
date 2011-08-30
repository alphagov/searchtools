module Searchtools

class Index
  
    STOP = ["the","of","to","and","a","for"]

    MIN_LENGTH = 1
    MAX_LENGTH = 6

    def initialize()
      @indices = {}
      (MIN_LENGTH..MAX_LENGTH).each do |i|
        @indices[i] = Hash.new
      end
    end

    def cleaned_words(phrase)
      words = phrase.split(/\W+/)
      words.reject {|s| s.length < MIN_LENGTH || STOP.include?(s) }.each do |word|
        yield word.downcase
      end
    end

		def index_page(title,url,tags)
			 index_phrase(title,{
          :title => title,
          :loc   => url,
          :tags  => tags
        })
		end

    def index_phrase(phrase,sr)
      cleaned_words(phrase) do |word|
        index(word,sr)
      end
    end

    def index(word,sr)
      indices = [word.length,MAX_LENGTH].min
      (MIN_LENGTH..indices).each do |i|
        sub = word[0...i]
        (@indices[i][sub] ||= []) << sr
      end
    end

    def all_terms_match?(term,title)
      cleaned_words(term) do |q|
        return false unless title.include? q
      end
      return true
    end

	  def quick_a_to_z
	 	  results = {}
		  ('a'..'z').each do |c|
				query = self.search(c,3).map do |r|
				 { 'label' => r[:title], 'url'   => r[:loc] }
				end
			  results[c] = query
		  end
			results
		end

    def search(term,num=10)
      results = []
      cleaned_words(term) do |q|
        index = [q.length,MAX_LENGTH].min
        q_term = q[0...index]
        matches = @indices[index][q_term] 
        break unless matches
        matches = matches.select {|m| m[:title].downcase.include? q }
        break if matches.empty?
        if results.empty?
          results = matches
        else
          results = results & matches
        end
      end
      results = results.select do |r|
        title = r[:title].downcase
        all_terms_match?(term,title)
      end
      results[0...num]
    end
  end
end
