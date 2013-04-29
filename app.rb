require 'rubygems'
require 'bundler'
Bundler.require
require 'bcrypt'
require 'date'
require 'dm-serializer/to_json'
require 'pusher'
require './database.rb'

set :root, File.dirname(__FILE__)

require_relative 'activity'

############################
#-------PUSHER KEY---------#
############################
Pusher.app_id = '42831'
Pusher.key = 'b0753433dcd3172ef750'
Pusher.secret = '10038631598936f297a4'

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
    @courses = Course.now

    @count = @courses.count

    erb :index
  
end

#HERE'S WHERE I AM

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
    
        #create a new person entry
        @p = Person.new
        puts params[:propic]
        if params[:propic] != ""
            puts "it thinks i have a pic"
            @p.createPersonPic(params[:firstname], params[:lastname], params[:email], params[:password], params[:location], params[:propic])

            #create the session id
            session[:email] = @p.email
            session[:firstname] = @p.firstname
            session[:lastname] = @p.lastname

            @page_title = "Please Choose Classes"
            @page_heading = "Please Enter Your Username And Password!"
            @forgotPassword = ""
            erb :profile
        
        else

            @p.createPerson(params[:firstname], params[:lastname], params[:email], params[:password], params[:location])

            #create the session id
            session[:email] = @p.email
            session[:firstname] = @p.firstname
            session[:lastname] = @p.lastname

            @page_title = "Please Choose Classes"
            @page_heading = "Please Enter Your Username And Password!"
            @forgotPassword = ""
            erb :profile

        end               
            
    else 
      @page_title = "Please Retype Your Password"
      @page_heading = "Please retype your password!"
      @forgotPassword = ""
      erb :signup
    end
  else 
      @page_title = "Email Already Exists"
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
    @interests = Interest.all 
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
                    :teacher => teach)
                    
                    if i = Interest.first(:keyword => params[:interest])
                        
                        p.setInterest(i)
                    end    
                end
            else 
                @p = p
                @page_title = "Change Your Profile"
                @page_heading = "You didn't enter your old password correctly!"
                erb :changeprofile
            end
            
        else
            if p.update(:firstname => params[:firstname], 
                :lastname => params[:lastname], 
                :email => params[:email],
                :teacher => params[:group1], 
                :propic => params[:propic],
                :teacher => teach)
                
                if i = Interest.first(:keyword => params[:interest])
                    
                    p.setInterest(i)
                end
            else 
                @p = p
                @page_title = "Change Your Profile"
                @page_heading = "You didn't enter your old password correctly!"
                erb :changeprofile
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
    @interests = Interest.all
    erb :addcourse
  
end

get '/courses' do
  
    if session[:email]
        p = Person.first(:email => session[:email])

        ###################################
        #######-----TO DO:---------########
        #sort out the classes that are too far away
        @courses = Course.all(:order=>[:date.asc])
        #@nearbyCourses = getLocation(@courses)

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
    
    @page_title = ":title"
    @p = Person.first(:email => session[:email])
    @count = @courses.count
    
    if @this_course.students != nil
        student = @this_course.students.first(:email => @p.email)
    end

    teacher = @this_course.teacher.first(:email => @p.email)

    if student
        @aStudent = true
        @aTeacher = false
    elsif teacher
        @aTeacher = true
        @aStudent = false
    else 
        @aTeacher = false
        @aStudent = false
    end

    if @this_course.students 
        @classCount = (@this_course.totstu - @this_course.students.count)
    else
        @classCount = @this_course.totstu
    end
  
    erb :single_course

end

post '/newcourse' do

    p = Person.first(:email => session[:email])
    
    if p


        @this_course = Course.new
        @courses = Course.all

        @this_course.createCourse(params[:title], params[:description], params[:location], 
            params[:date], params[:totstu], params[:photo], p, params[:interest])
        
        @count = @courses.count
        @classCount = @this_course.totstu
        

        erb :single_course
    else
        "You're not logged in"
    end     
end

get '/livecourse/:course' do

    @p = Person.first(:email => session[:email])
    
    course = Course.first(:title => params[:course])

    @courses = Course.all 
    @this_course = course

    @page_title = @this_course.title.capitalize

    erb :livecourse

end

get '/enrollclass/:course' do

    @p = Person.first(:email => session[:email])
    
    course = Course.first(:title => params[:course])
    

    student = course.students.first(:email => @p.email)
    puts student.inspect
    
    if !student
        course.add_student @p
        @aStudent = true
    else 
        @aStudent = true
    end

    @classCount = course.totstu - course.students.count

    @courses = Course.all 
    @this_course = course

    @page_title = ":course"

    @count = @courses.count
  
    #TODO - maybe redirect instead of this
    erb :single_course
    
end

get '/leaveclass/:course' do

    p = Person.first(:email => session[:email])
    course = Course.first(:title => params[:course])
    
    puts p.email
    course.delete_student p

    @this_course = course

    @courses = Course.all

    @count = @courses.count
    if @this_course.students 
        @classCount = (@this_course.totstu - @this_course.students.count)
    else
        @classCount = @this_course.totstu
    end

    #TODO - maybe redirect instead of this
    erb :single_course


end

get '/users/:slug' do

    @this_profile = Profile.first(:slug => params[:slug])
    #raise Exception, @date = @this_course.strftime([format='%A %d %b %Y'])
    @page_title = ":slug"

    @this_person = Person.get(@this_profile.person_id)
    @people = Person.all
    @count = @people.count    
    puts @this_person.name
    

    erb :single_user
    
    
end

get '/users' do
    @persons = Person.all

    erb :users
end

get '/terms' do
    "This is where the terms will be. Press the back button to go back"
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

get '/setinterests' do
    
    interests = [
    #######################################---------INTERESTS ALREADY IN THE DATABASE----------------#####################################################
    "Arts", "Audio", "Biology & Life Sciences", "Business & Management", "Chemistry", "CS: Artificial Intelligence", "CS: Artificial Intelligence", 
                    "CS: Software Engineering", "CS: Systems & Security", "CS: Theory", "Economics & Finance", "Education", "Energy & Earth Sciences",
                    "Engineering", "Film", "Food and Nutrition", "Health & Society", "Humanities", "Information, Tech, and Design", "Law", "Mathematics", "Medicine",
                    "Music", "Physical & Earth Sciences", "Physics", "Social Sciences", "Statistics and Data Analysis"]


    interests.each do |interest|
        dbInterest = Interest.new
        dbInterest.keyword = interest
        dbInterest.save
    end
    
end

post '/chat' do

    p = Person.first(:email => session[:email])

    chat_info = params[:chat_info]

    channel_name = nil

    if( !chat_info )
      status 400
      puts 'chat_info must be provided'
    end

    if( !request.referer )
      status 400
      puts 'channel name could not be determined from request.referer'
    end

    channel_name = get_channel_name(request.referer)
    options = sanitise_input(chat_info)

    activity = Activity.new('chat-message', options['text'], options)

    data = activity.getMessage()

    response = Pusher[channel_name].trigger('chat_message', data)

    result = {'activity' => data, 'pusherResponse' => response}

    status 200
    headers \
      'Cache-Control' =>  'no-cache, must-revalidate',
      'Content-Type' =>  'application/json'
    
    body result.to_json
end

def get_channel_name(http_referer)
    pattern = /(\W)+/
    channel_name = http_referer.gsub pattern, '-'
    return channel_name
end

def sanitise_input(chat_info)
    email = chat_info['email']?chat_info['email']:''
    
    options = {}
    options['displayName'] = escape_html(chat_info['nickname']).slice(0, 30)
    options['text'] = escape_html(chat_info['text']).slice(0, 300)
    options['email'] = escape_html(email).slice(0, 100)
    options['get_gravatar'] = true
    return options
end

