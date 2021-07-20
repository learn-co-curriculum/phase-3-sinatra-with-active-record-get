class ApplicationController < Sinatra::Base

  get '/' do
    { message: "Hello world" }.to_json
  end

end
