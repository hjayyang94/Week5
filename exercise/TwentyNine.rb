
$stopwords = File.read("../stop_words.txt").split(",").concat(Array("a".."z"))
$word_space = Queue.new
$freq_space = Queue.new

def process_words
    word_freqs = {}
    while true
        begin
            word = $word_space.pop(non_block=true)
        rescue
            puts "Queue is empty"
            break
        end

        if !$stopwords.include? word
            if !word_freqs.include? word
                word_freqs[word] = 1
            else
                word_freqs[word] = word_freqs[word]+1
            end
        end
    end

    $freq_space.push(word_freqs)
end

data = File.read(ARGV[0]).split(/[\W_]+/).map(&:downcase)

data.each do |word|
    $word_space.push(word)
end

$workers = []
[0..5].each do |d|
    $workers << Thread.new do
        process_words()
    end
end


$workers.each { |t| t.join}

word_freqs = {}

while !$freq_space.empty?
    freqs = $freq_space.pop
    freqs.each do |w,c|
        if word_freqs.include? w
            count = word_freqs[w] + freqs[w]
        else
            count = freqs[w]
        end
        word_freqs[w] = count
    end
end

freqs_sorted = word_freqs.sort_by{|word, count| -count}

for(w,c) in freqs_sorted[0..25]
    puts w + " - " + c.to_s + "\n"
end