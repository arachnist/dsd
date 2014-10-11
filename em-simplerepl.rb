module SimpleRepl
    def receive_data data
        process = proc {
            begin
                eval(data)
            rescue ::Exception => e
                e.inspect
            end
        }
        output = proc { |r| send_data "> #{r}\n" }

        EventMachine.defer(process, output)
    end
end
