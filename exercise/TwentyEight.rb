class ActiveWFObject < Thread 
    def initialize()
        super do
            @name = self.class.to_s
            @queue = Queue.new
            @stopMe = false
            @thread = Thread.new {
                run()
            }
        end
        
    end

    def self.queue
        @queue
    end

    def self.name
        @name
    end

    def run()
        while !@stopMe
            message = @queue.get()
            self.dispatch(message)
            if message[0] == "die"
                @stopMe = true
            end
        end
    end
end

def send(receiver, message)
    receiver.queue.put(message)
end

class DataStorageManager < ActiveWFObject
    def initialize()
        super()
    end

    def dispatch(message)
        if message[0] == "init"
            self.init(message[1,message.lenght()])
        elsif message[0] == "send_word_freqs"
            self.process_words(message[1,message.lenght()])
        else
            send(self.stop_word_manager, message)
        end
    end

    def init(message)
        path_to_file = message[0]
        self.stop_word_manager = message[1]
        self.data = File.read(path_to_file).split(/[\W_]+/).map(&:downcase)
    end

    def process_words(message)
        recipient = message[0]
        self.data.each do |w|
            send(self.stop_word_manager, ["filter",w])
        end
        send(self.stop_word_manager, ["top25", recipient])
    end

end

class StopWordManager < ActiveWFObject

    def initialize()
        super()
        @stop_words = []
    end


    def dispatch(message)
        if message[0] == "init"
            self.init(message[1,message.length()])
        elsif message[0] == "filter"
            self.filter(message[1,message.length()])
        else
            send(self.word_freqs_manager, message)
        end
    end 

    def init(message)
        @stop_words = File.read("../stop_words.txt").split(",")
        @stop_words.concat(Array("a".."z"))
        self.words_freqs_manager = message[0]
    end

    def filter(message)
        word = message[0]
        if !@stop_words.include? word
            send(self.word_freqs_manager, ["word",word])
        end
    end
end

class WordFrequencyManager < ActiveWFObject

    def initialize()
        super()
        @word_freqs = {}
    end

    def self.name
        @name
    end

    def dispatch(message)
        if message[0] == "word"
            self.increment_count(message[1,message.length()])
        elsif message[0] == "top25"
            self.top25(message[1,message.length()])
        end
    end 

    def increment_count(message)
        if !@word_freqs.include? word
            @word_freqs[word] = 1
        else
            @word_freqs[word] = @word_freqs[word]+1
        end
    end
    
    def top25(message)
        recipient = message[0]
        freqs_sorted = @word_freqs.sort_by{|word, count| -count}
        send(recipient, ["top25", freqs_sorted])
    end
end

class WordFrequencyController < ActiveWFObject
    def initialize()
        super()
    end
    
    def dispatch(message)
        if message[0] == "run"
            self.run(message[1,message.length()])
        elsif message[0] == "top25"
            self.display(message[1,message.length()])
        else
            raise Exception.new "Message not understood #{message[0]}"
        end
    end

    def run(message)
        self.storage_manager = message[0]
        send(self.storage_manager, ["send_word_freqs", self])
    end

    def display(message)
        word_freqs = message[0]
        for(w,c) in words_freqs[0..25]
            puts w + " - " + c.to_s + "\n"
        end

        send(self.storage_manager,["die"])
        self.stopMe = true
    end
end

word_freq_manager = WordFrequencyManager.new
stop_word_manager = StopWordManager.new
send(stop_word_manager, ["init", word_freq_manager])

storage_manager = DataStorageManager.new
send(storage_manager, ["init", ARGV[0], stop_word_manager])

wfcontroller = WordFrequencyController.new
send(wfcontroller, ["run", storage_manager])

[word_freq_manager,stop_word_manager,storage_manager,wfcontroller].each do |t|
    t.join()
end


        
        