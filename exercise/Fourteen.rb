require "set"

class WordFrequencyFramework
    def initialize()
        @load_event_handlers = []
        @dowork_event_handlers = []
        @end_event_handlers = []
    end

    def register_for_load_event(handler)
        @load_event_handlers.push(handler)
    end

    def register_for_dowork_event(handler)
        @dowork_event_handlers.push(handler)
    end

    def register_for_end_event(handler)
        @end_event_handlers.push(handler)
    end

    def run(path_to_file)
        @load_event_handlers.each do |h|
            h.call(path_to_file)
        end
        @dowork_event_handlers.each do |h|
            h.call()
        end
        @end_event_handlers.each do |h|
            h.call()
        end
    end
end



class DataStorage
    
    def initialize(wfapp, stop_word_filter)
        @data = ""
        @word_event_handlers = []
        @stop_word_filter = stop_word_filter
        wfapp.register_for_load_event(lambda{|y|loads(y)})
        wfapp.register_for_dowork_event(lambda{produce_words()})

    end

    def loads(path_to_file)
        @data = File.read(path_to_file).split(/[\W_]+/).map(&:downcase)
    end

    def produce_words()
        @data.each do |w|
            if (!@stop_word_filter.is_stop_word(w))
                
                @word_event_handlers.each do |h|
                    h.call(w)
                end
            end
        end
    end

    def register_for_word_event(handler)
        @word_event_handlers.push(handler)
    end


end

class StopWordFilter

    def initialize(wfapp)
        @stop_words = []
        wfapp.register_for_load_event(lambda{|y| loads(y)})
    end

    def loads(ignore)
        @stop_words = File.read("../stop_words.txt").split(",")
        @stop_words.concat(Array("a".."z"))
    end

    def is_stop_word(word)
        return @stop_words.include? word
    end

end

class WordFrequencyCounter
    
    def initialize(wfapp, data_storage)
        @word_freqs = {}
        data_storage.register_for_word_event(lambda{|w|increment_count(w)})
        wfapp.register_for_end_event(lambda{print_freqs()})
    end

    def increment_count(word)
        if !@word_freqs.include? word
            @word_freqs[word] = 1
        else
            @word_freqs[word] = @word_freqs[word]+1
        end
    end

    def print_freqs()
        words = @word_freqs.sort_by{|word, count| -count}
        for(w,c) in words[0..25]
            puts w + " - " + c.to_s + "\n"
        end
    end

end

class UniqueZCounter
    def initialize(wfapp, data_storage)
        @unique_word = Set[]
        data_storage.register_for_word_event(lambda{|w| add(w)})
        wfapp.register_for_end_event(lambda{printNumZ()})
    end

    def add(word)
        if word.include? "z"
            @unique_word.add(word)
        end
    end

    def printNumZ()
        puts "Number of Unique Non-stopwords with Z: #{@unique_word.length()}" 
    end
end


wfapp = WordFrequencyFramework.new()
stop_word_filter = StopWordFilter.new(wfapp)
data_storage = DataStorage.new(wfapp,stop_word_filter)
word_freq_counter = WordFrequencyCounter.new(wfapp,data_storage)
unique = UniqueZCounter.new(wfapp,data_storage)
wfapp.run(ARGV[0])
