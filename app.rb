ENV["RACK_ENV"] ||= "development"

require 'sinatra/base'
require 'sinatra/flash'
require_relative 'data_mapper_setup'

class ChitterApp < Sinatra::Base
  use Rack::MethodOverride
  enable :sessions
  set :session_secret, 'super secret'
  register Sinatra::Flash


  get '/' do
    'Hello ChitterApp!'
    redirect '/peeps'
  end

  get '/peeps' do
    @peeps = Peep.all.reverse
    erb :'peeps/index'
  end

  post '/peeps' do
    peep = Peep.new(peep: params[:peep], time: Time.now )
    peep.user = current_user
    peep.save
    redirect '/peeps'
  end

  get '/peeps/new' do
    erb :'peeps/new'
  end

  get '/users/new' do
    @user = User.new
    erb :'/users/new'
  end

  post '/users/new' do
    @user = User.create(username: params[:username],
                        email: params[:email],
                        password: params[:password],
                        password_confirmation: params[:password_confirmation])
    if @user.save
      session[:user_id] = @user.id
      redirect '/peeps'
    else
      flash.now[:errors] = @user.errors.full_messages
      erb :'/users/new'
    end
  end

  get '/sessions/new' do
    erb :'sessions/new'
  end

  post '/sessions' do
    user = User.authenticate(params[:email], params[:password])
    if user
      session[:user_id] = user.id
      redirect to '/peeps'
    else
      flash.now[:failed_login] = ['Username or password incorrect']
      erb :'sessions/new'
    end
  end

  delete '/sessions' do
    session[:user_id] = nil
    flash.keep[:notice] = 'See you again soon'
    redirect to '/peeps'
    end

  helpers do
    def current_user
      @current_user ||= User.get(session[:user_id])
    end
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
