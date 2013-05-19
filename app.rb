require 'rubygems'
require 'bundler'
Bundler.require
require 'bcrypt'
require 'date'
require 'dm-serializer/to_json'
require 'pusher'
require './database.rb'
require 'digest/md5'
require 'json'

set :root, File.dirname(__FILE__)

require_relative 'activity'

# Sessions for the temp cookie
enable :sessions

############################
#-------PUSHER KEY---------#
############################
Pusher.app_id = '42831'
Pusher.key = 'd7de9fa48c3e423f3218'
Pusher.secret = 'a002b875422e6d5558b0'

@google_map_key = "AIzaSyB-vkhfS6BiwMLzMCrkeAQJpnjxmQn8U4Y"

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



end

def resetSession
    session[:firstname] = nil
    session[:lastname] = nil
    session[:email] = nil
end

def getLocation(courses)
    #this will change to get specific courses
    return courses = Courses.all
end

#-------------------------------------------------------#
################### FUNCTIONS AND ROUTES ################
#-------------------------------------------------------#
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

post "/login" do

    match = Person.first(:email => params[:email])

    if match
        
        @p = match
        #raise Exception, @p
        
        if @p.password == params[:password]

            @page_title = "Profile"
            
            session[:email] = @p.email
            session[:firstname] = @p.firstname.capitalize
            session[:lastname] = @p.lastname.capitalize
            #create the date to sort against

            redirect "/profile"
            
        else 
            @page_title = "Login"

            @page_title = "Please Check Password"
            @page_heading = "Please Check Password"
            @forgotPassword = "Forgot Password?"
            erb :login

        end
    
    else

        @page_title = "Login"
    
        @page_title = "Please Check email"
        @page_heading = "That email is already in use!"
        @forgotPassword = "Forgot Password?"
        erb :login   
    
    end

end

post "/signedup" do
  user = Person.first(:email => params[:email])
  
  #make sure there isn't a user already listed in the database
  if !user 
    
    #make sure the passwords match
    if params[:password] == params[:checkpassword]
    
        #create a new person entry
        @p = Person.new
        
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

get '/profile' do

    @p = Person.first(:email => session[:email])

    if @p 
        #raise Exception, @p
        @page_title = "Your Profile"
        @page_heading = "Your Profile"
        erb :profile
    else 
        resetSession
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
        resetSession
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
        
        resetSession
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
    
    erb :courses
  
end

get '/courses/:title' do

    if session[:email]
        @courses = Course.all 
        @this_course = Course.first(:title => params[:title])
    
        @page_title = :title
        @count = @courses.count

        @p = Person.first(:email => session[:email])
        
        if @this_course.students.first(:email => @p.email)
            @aStudent = true
            @aTeacher = false
            @browser = false
        elsif @this_course.teacher.email == @p.email 
            @aStudent = false
            @aTeacher = true
            @browser = false
        end 
    
        @comments = @this_course.comments

        if @this_course.students 
            @classCount = (@this_course.totstu - @this_course.students.count)
        else
            @classCount = @this_course.totstu
        end
    else
        @courses = Course.all
        @this_course = Course.first(:title => params[:title])
        @page_title = :title
        @count = @courses.count
        @aStudent = false
        @aTeacher = false
        @browser = true

        #TODO: ADD COMMENTS
        @comments = @this_course.comments

        if @this_course.students 
            @classCount = (@this_course.totstu - @this_course.students.count)
        else
            @classCount = @this_course.totstu
        end

    end
  
    erb :single_course

end

get '/editcourse/:title' do

    if session[:email]
        @this_course = Course.first(:title => params[:title])
    
        @page_title = :title

        @p = Person.first(:email => session[:email])
        
        @comments = @this_course.comments

        if @this_course.students 
            @classCount = (@this_course.totstu - @this_course.students.count)
        else
            @classCount = @this_course.totstu
        end

        @interests = Interest.all

        erb :changecourse
    else
        resetSession
        @page_title = "Please Login"
        @page_heading = "Please Login"
        erb :login 
    end
end

post '/updatecourse' do

    params.each do |param|
        puts param 
    end

    p = Person.first(:email => session[:email])
    c = Course.first(:title => params[:coursetitle])

    if p && c && p.name == c.teacher.name

        if c.title != params[:title]
            title = params[:title]
        end

        date = DateTime.strptime(params[:date]+" "+params[:hour]+":"+params[:minute]+":00"+" "+params[:daynight],
            '%Y-%m-%d %I:%M:%S %p')
        puts date

        if c.update(:title => params[:title], 
                    :description => params[:description], 
                    :location => params[:location],
                    :date => date,
                    :totstu => params[:totstu],
                    :coursepic => params[:photo])
        
            if c.setInterest params[:interest]
                puts "setinterest"
            end 

            @aStudent = false
            @aTeacher = true
            @browser = false
            
            @courses = Course.all
            @this_course = c 
            @page_title = @this_course.title
            @count = @courses.count
            @comments = @this_course.comments

            if @this_course.students 
                @classCount = (@this_course.totstu - @this_course.students.count)
            else
                @classCount = @this_course.totstu
            end

            erb :single_course

        else
            raise Exception, c
        end
        
        

    else
        
        resetSession
        @page_title = "Please Login"
        @page_heading = "Please Login"
        erb :login 
        
    end
end

post '/newcourse' do
    
    p = Person.first(:email => session[:email])
    
    if p

        @this_course = Course.new
        @courses = Course.all
        date = DateTime.strptime(params[:date]+" "+params[:hour]+":"+params[:minute]+":00"+" "+params[:daynight],
            '%Y-%m-%d %I:%M:%S %p')
        puts date
        @this_course.createCourse(params[:title], params[:description], params[:location], 
            date, params[:totstu], params[:photo], p, params[:interest])
        
        @count = @courses.count
        @classCount = @this_course.totstu
        
        @aTeacher = true
        @aStudent = false

        erb :single_course
    else
        "You're not logged in"
    end     
end

get '/startclass/:course' do

    @p = Person.first(:email => session[:email])
    
    course = Course.first(:title => params[:course])

    course.createChannelName
    
    @courses = Course.all 
    @this_course = course
    if @this_course.chat == nil
        @this_course.createChat
    end

    @page_title = @this_course.title.capitalize

    erb :livecourse

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
    @page_title = :slug

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

    resetSession
    redirect "/"

end

get '/inbox' do

    @p = Person.first(:email => session[:email])
    
    if @p 
        @count = @p.getInbox.count
        @sentCount = @p.getSent.count
        erb :inbox
    else
        resetSession
        @page_title = "Please Login"
        @page_heading = "Please Login"
        erb :login 
    end
end

post '/new_message' do

    m = Message.new

    sender = Person.first(:email=>session[:email])
    receiver = Person.first(:name => params[:receiver])
    m.subject = params[:subject]
    m.bodytext = params[:message]

    m.sendMail(sender, receiver)

    redirect('/inbox')

end

post '/chat' do

    chat_info = params[:chat_info]

    chat_info.each do |info|
        puts "this is chat info " + info.to_json
    end

    p = Person.first(:id => chat_info['id'])
    c = Course.first(:id => chat_info['courseid'])

    puts "the person's name is " + p.name
    puts "The course's title is " + c.title + " and the courses channel is " + c.createChannelName

    channel_name = nil

    if( !chat_info )
      status 400
      puts 'chat_info must be provided'
    end

    channel_name = get_channel_name(chat_info["channel"])
    puts "the created channel_name is " + channel_name
    options = sanitise_input(chat_info)

    puts "the newly sanitised input is "
    options.each do |option|
        puts option
    end

    activity = Activity.new('chat-message', options['text'], options)

    data = activity.getMessage()

    data.each do |dat|
        puts dat.to_json
    end

    if (c.addRemark(channel_name, p, options['text']))
        puts "added a remark"
        response = Pusher[channel_name].trigger('chat_message', data)

        result = {'activity' => data, 'pusherResponse' => response}

        status 200
        headers \
            'Cache-Control' =>  'no-cache, must-revalidate',
            'Content-Type' =>  'application/json'
    
        puts result.to_json
    else 



    end

end

def get_channel_name(http_referer)
    pattern = /(\W)+/
    channel_name = http_referer.gsub pattern, '-'
    return channel_name
end

def sanitise_input(chat_info)

    email = chat_info['email']?chat_info['email']:''
    
    options = {}
    options['id'] = chat_info['id']
    options['channel'] = escape_html(chat_info['channel']).slice(0,70)
    options['displayName'] = escape_html(chat_info['nickname']).slice(0, 30)
    options['text'] = escape_html(chat_info['text']).slice(0, 300)
    options['email'] = escape_html(email).slice(0, 100)
    options['propic'] = chat_info['propic']
    return options
end

################################################################
#--------------ALL OF THE HELPER ROUTES FOR TESTING------------#
################################################################

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

#--------------------------------------------------------#
#--------------- TESTING THE CHAT -----------------------#
#--------------------------------------------------------#

get '/testchat' do
    erb :testChat
end

post '/testchat/login' do
    session[:username] = params[:username]  
    session[:userid] = Digest::MD5.hexdigest(session[:username])
    puts session[:userid]
    success = {'success' => true}
    success.to_json
end

post '/pusher/auth' do
    @socket_id = params[:socket_id]
    @channel_name = params[:channel_name]
    puts @socket_id
    puts @channel_name
    # if session[:username].hasAccessTo(@channel_name) == false

    # end

    response = Pusher[@channel_name].authenticate(@socket_id,{
        user_id: session[:username],
        user_info: {} # optional
    })
    puts response
    response.to_json
end

get '/test_associations' do
    CoursePerson.all(:person_id => 5) do |course|
        puts course
    end
end

get '/test_ajax' do
    
    @course = Course.all

end

post '/testchat/send_message' do
    @message = params[:message]

    @message = "<strong>" + session[:username] + "</strong>:" + @message

    Pusher.trigger('presence-nettuts', 'new_message', @message)

    response = {'message' => @message, 'success' => true}
    puts response
    response.to_json
end
