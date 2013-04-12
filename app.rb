require 'rubygems'
require 'bundler'
Bundler.require
require 'bcrypt'
require 'date'
require './database.rb'

set :root, File.dirname(__FILE__)

# Sessions for the temp cookie
enable :sessions

#----------------------------------------------------
# These functions are defined for all the quick stuff 
# that needs to be defined first
helpers do
    
    def login?
        if session[:email] == nil
          return false
        else
          return true
        end
    end

    def username
        session[:email]
    end

    def firstname
        session[:firstname] 
    end

    def lastname
        session[:lastname]
    end

end

before do
    #session[:email] = nil
    @upcomingCourses = upcomingCoursesFunc
end

#----------------------------------------------
# functions aiding in the sorting of this stuff
#this is to the sort the classes by date.
def sortingTheClasses (upcomingClasses)
    #i need to take the values out of the database and 
    #make a hash then return the hash so that it can 
    #access the data members better by date. 
    upcomingClasses.sort_by{ |k, v| v[:date]}.reverse
end

def upcomingCoursesFunc

    Course.all(:order => [ :date.asc ])
    #count up all the courses that are in the next
    #couple of days so that we can display them to
    #people coming to the site
    #if(allClasses)
    #
    #  #get the exact time on the server when a person starts
    #  thisTime = Time.new
    #
    #    for thisClass in allClasses
    #        
    #        #check the time and date of the classes and 
    #        #figure out if it's within three days. This
    #        #needs work
    #        if thisClass.Date - thisTime.local.to_date < 3
    #           upcomingClasses += thisClass
    #        end
    #
    #    end
    #
    #    #Once I work out the above this will sort the classes 
    #    #and return the sorted classes
    #    #sortingTheClasses(upcomingClasses)
    #end

end


#-------------------------------------------------------
# Routes to take!
# Main route  - this is the form where we take the input
get '/' do

  @page_title = "Pointers*"
  
  erb :index
  
end

get '/about' do

    @page_title = "About Us"
    erb :about

end

get '/signup' do

  @page_title = "Sign Up"
  @page_heading = "Enter a new username and password!"


  erb :signup

end

post "/signedup" do
  user = Person.first(:email => params[:email])
  #raise Exception, user
  #make sure there isn't a user already listed in the database
  if !user 
    
    #make sure the passwords match
    if params[:password] == params[:checkpassword]

        #generate the encryption
    
        #create the session id
        session[:email] = params[:email]
        # raise Exception, session[:email]
        
        #create a new person entry
        @p = Person.new(:firstname => params[:firstname], 
                          :lastname => params[:lastname], 
                          :email => params[:email],
                          :password => params[:password],
                          :teacher => false)

        puts @p.valid?
        # raise @p.inspect

        if @p.save
            puts "saved"
            @page_title = "Please Choose Classes"
            @page_heading = "Please Enter Your Username And Password!"
            @forgotPassword = ""
            erb :profile
        else
            puts "did not save"
            raise Exception, @p.errors.inspect
        end
        #p = Person.new
        #p.email = session[:email]
        #p.password_salt = password_salt
        #p.password_hash = password_hash
        #p.firstname = params[:firstname]
        #p.lastname = params[:lastname]
        #p.teacher = false
        #raise Exception, p.save
        #p.save
    else 
      @page_title = "Please Retype Your Password"
      @page_heading = "Please retype your password!"
      @forgotPassword = ""
      erb :signup
    end
  else 
      @page_title = "Please Check email"
      @page_heading = "That email is already in use!"
      @forgotPassword = "Forgot Password?"
      erb :signup
  end
end

post "/login" do

  match = Person.first(:email => params[:email])

    if match
        
        @p = match
        #raise Exception, @p
        
        if @p.password_hash == BCrypt::Engine.hash_secret(params[:password], @p.password_salt)
            
            session[:email] = @p.email
            session[:firstname] = @p.firstname.capitalize
            session[:lastname] = @p.lastname.capitalize
            
            redirect "/profile"
            
        else 
  
            "The Password didn't match"
        
        end
    
    else
    
        "You didn't get a match"
    
    end

end

get '/profile' do

    @p = Person.first(:email => session[:email])

    if @p 
        #raise Exception, @p
        @page_title = "Your Profile"
        @page_heading = "Your Profile"
        erb :profile
    else 
        "You need to login"
    end

end

post '/updateprofile' do

    p = Person.first(:email => session[:email])

    if p

        if params[:password] != "" && params[:checkpassword] != ""
            if p.update(:firstname => params[:firstname], 
                    :lastname => params[:lastname], 
                    :email => params[:email],
                    :password_salt => params[:password],
                    :password_hash => params[:checkpassword],
                    :teacher => params[:group1], 
                    :interest1 => params[:interests])
            else
                raise Exception, p.errors.inspect
            end
        else
            if p.update(:firstname => params[:firstname], 
                    :lastname => params[:lastname], 
                    :email => params[:email],
                    :password_salt => p.password_salt,
                    :password_hash => p.password_hash,
                    :teacher => params[:group1], 
                    :interest1 => params[:interests])
            else
                raise Exception, p.errors.inspect
            end
        end

        redirect "http://itp.nyu.edu/~rtb288/sinatra/grandio/profile"

    else
        
        "You didn't update anything idiot"
    end

end

get '/logout' do

    session[:firstname] = nil
    session[:lastname] = nil
    session[:email] = nil
    redirect "http://itp.nyu.edu/~rtb288/sinatra/grandio/"

end