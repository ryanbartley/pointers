require 'rubygems'
require 'bundler'
Bundler.require
require 'bcrypt'
require 'date'
require 'dm-serializer/to_json'
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

    Course.all(:order => [ :date.desc ])
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

def getLocation(courses)
    #this will change to get specific courses
    return courses = Courses.all
end


#-------------------------------------------------------
# Routes to take!
# Main route  - this is the form where we take the input
get '/' do

    @page_title = "Pointers*"
  
    @google_map_key = "AIzaSyB-vkhfS6BiwMLzMCrkeAQJpnjxmQn8U4Y"
    @classes = Course.now

    @count = @classes.count

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
        
        if @p.password == params[:password]
            
            session[:email] = @p.email
            session[:firstname] = @p.firstname.capitalize
            session[:lastname] = @p.lastname.capitalize
            #create the date to sort against

            redirect "/profile"
            
        else 

            @page_title = "Please Check Password"
            @page_heading = "Please Check Password"
            @forgotPassword = "Forgot Password?"
            erb :login

        end
    
    else
    
        @page_title = "Please Check email"
        @page_heading = "That email is already in use!"
        @forgotPassword = "Forgot Password?"
        erb :login   
    
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
        session[:email] = nil
        @page_title = "Please Login"
        @page_heading = "Please Login"
        erb :login 
    end

end

get '/changeprofile' do

    @p = Person.first(:email => session[:email])

    if @p 
        #raise Exception, @p
        @page_title = "Change Your Profile"
        @page_heading = "Change Your Profile"
        erb :changeprofile
    else 
        session[:email] = nil
        @page_title = "Please Login"
        @page_heading = "Please Login"
        erb :login 
    end

end


####### There are still errors with changing your password ################
post '/updateprofile' do

    p = Person.first(:email => session[:email])

    if p

        if params[:teach] == "true"
            teach = true
        else 
            teach = false
        end
    
        if p.email != params[:email]
            session[:email] = params[:email]
        end

        if params[:password] != "" && params[:newpassword] != ""
            if p.password == params[:password]
                if p.update(:firstname => params[:firstname], 
                    :lastname => params[:lastname], 
                    :email => params[:email],
                    :password => params[:newpassword],
                    :teacher => params[:group1],
                    :propic => params[:propic], 
                    :interest1 => params[:interests],
                    :teacher => teach)
                else
                    raise Exception, p.errors.inspect
                end
            else 
                @p = p
                @page_title = "Change Your Profile"
                @page_heading = "You didn't enter your password correctly!"
                erb :changeprofile
            end
            
        else
            if p.update(:firstname => params[:firstname], 
                    :lastname => params[:lastname], 
                    :email => params[:email],
                    :teacher => params[:group1], 
                    :propic => params[:propic], 
                    :interest1 => params[:interests],
                    :teacher => teach)
            else
                raise Exception, p.errors.inspect
            end
        end

        redirect "/profile"

    else
        
        session[:firstname] = nil
        session[:lastname] = nil
        session[:email] = nil
        @page_title = "Please Login"
        @page_heading = "Please Login"
        erb :login 
        
    end

end

get '/addcourse' do
  
    @page_title = "Add Course"
    erb :addcourse
  
end

get '/courses' do
  
    if session[:email]
        p = Person.first(:email => session[:email])

        ###################################
        #######-----TO DO:---------########
        #sort out the classes that are too far away
        @courses = Course.all(:order=>[:date.asc])
        @nearbyCourses = getLocation(@courses)

        if p.teacher == true
            @addcourses = true
        else 
            @addcourses = false
        end
        @page_title = "Courses"
    else
        @courses = Course.all(:order=>[:date.asc])
        @page_title = "Courses"
    end
  
      @courses = Course.all(:order=>[:date.asc])
      @page_title = "Courses"
      
      erb :courses
  
end

get '/courses/:title' do

    @courses = Course.all 
    @this_course = Course.first(:title => params[:title])
    #raise Exception, @date = @this_course.strftime([format='%A %d %b %Y'])
    @page_title = ":title"

    @count = @courses.count
  
    erb :single_course

end

post '/newcourse' do
  
    p = Person.first(:email => session[:email])
    
    if p.teacher == true
  
        
      if @course = Course.new(:date => params[:date],
                             :totstu => params[:totstu],
                             :location => params[:location],
                             :instructorfirst => p.firstname,
                             :instructorlast => p.lastname,
                             :title => params[:title],
                             :description => params[:description],
                             :interest => params[:interest])

        #CoursePerson.create(:person => p, :course => @course, :type => :teacher)

        
        if @course.persons << p 
            
          if p.courses << @course

            if @course.save && p.save
                redirect "/courses"
            else
                raise Exception, "I'm inside"
                "Your course didn't save." 
            end
          else
            "Your courses didn't setup with the person"
          end
        else
            "It didn't save"
        end
      else
        raise Exception, course.errors.inspect
      end
    else
        "You're not a teacher"
    end     
end

get '/enrollclass' do

    refer = "#{env['HTTP_REFERER']}"
    
end

get '/logout' do

    session[:firstname] = nil
    session[:lastname] = nil
    session[:email] = nil
    redirect "/"

end

get '/test_associations' do
    CoursePerson.all(:person_id => 5) do |course|
        puts course
    end
end

get '/test_ajax' do
    
    @course = Course.all


end