DataMapper::setup(:default, ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite")

DataMapper::Model.raise_on_save_failure = true

class CoursePerson
    include DataMapper::Resource

    property :course_id,  Integer, :key => true
    property :person_id,  Integer, :key => true
    property :type,       String,  :default => "student"

    belongs_to :person, :child_key => [:person_id]
    belongs_to :course, :child_key => [:course_id]
end

class Person
    include DataMapper::Resource
    include BCrypt
    
    property :id            , Serial  , :key => true
    property :firstname     , String  , :required => true, :length => 255
    property :lastname      , String  , :required => true, :length => 255
    property :email         , String  , :required => true, :length => 255
    property :password      , BCryptHash
    property :location      , String
    property :created_at    , DateTime
    property :lastLogin     , DateTime
    property :teacher       , Boolean , :default => false
    property :propic        , String  , :length => 255, :default => "http://critterapp.pagodabox.com/img/user.jpg"
    property :totalrating   , Integer , :default => 0
    property :totalrated    , Integer , :default => 0
    property :aboutme       , Text 
    property :lat           , Float
    property :long          , Float
    property :geoloc        , String
  
    class Link
  
        include DataMapper::Resource
  
        storage_names[:default] = 'people_links'
  
        # the person who is following someone
        belongs_to :follower, 'Person', :key => true
  
        # the person who is followed by someone
        belongs_to :followed, 'Person', :key => true
  
    end
  
    ##################################################
    ####### ASSOCIATIONS #############################
    ##################################################
  
    #########---------PEOPLE ASSOCIATIONS---------#########
    #TO DO: BOTH OF THESE LINK BOTH OF THEM TO EACH OTHER.
    #YOU SHOULD BE ABLE TO FOLLOW SOMEONE WITHOUT THEM FOLLOWING
    #YOU.
    has n, :links_to_followed_people, 
        'Person::Link', 
        :child_key => [:follower_id]
      
  
    has n, :links_to_followers, 
        'Person::Link', 
        :child_key => [:followed_id]
  
    has n, :followed_people, self,
        :through => :links_to_followed_people, # The person is a follower
        :via     => :followed
  
    has n, :followers, self,
        :through => :links_to_followers, # The person is followed by someone
        :via     => :follower
    
    ########------COURSE ASSOCIATION------------######
    has n, :courses, :through => :course_person, :required => false
  
  
    #TO DO - INBOX DOESN'T WORK FOR SOME REASON
    #######------MESSAGE ASSOCIATION------------######
    has n, :inbox, 'Message', :child_key => [ :target_id ]#, :order => :date.desc
    has n, :sent, 'Message', :child_key => [ :source_id ]#, :order => :date.desc
  
    ######-------COMMENTS ASSOCIATION-------##########
    has n, :comments
  
    ######-------PROFILE ASSOCIATION--------##########
    has 1, :profile
  
    ######-------INTERESTS ASSOCIATION------##########
    has n, :interests, :through => Resource
  
    ##################################################
    ####### HELPER FUNCTIONS #########################
    ##################################################
  
    #######---------BEFORE SAVE----------------#######
    before :save do
      
    end
  
    def name
        self.firstname.capitalize + " " + self.lastname.capitalize
    end
  
    def createPersonPic(firstname, lastname, email, password, location, propic, lat, long, geoloc)
        self.firstname = firstname
        self.lastname = lastname
        self.email = email.downcase
        self.password = password
        self.location = location
        self.propic = propic
        created_at = DateTime.now
        self.lat = lat
        self.long = long
        self.geoloc = geoloc
        lastLogin = created_at
        self.setProfile
        self.save
    end
  
    def createPerson(firstname, lastname, email, password, location, lat, long, geoloc)
        self.firstname = firstname
        self.lastname = lastname
        self.email = email.downcase
        self.password = password
        self.location = location
        created_at = DateTime.now
        self.lat = lat
        self.long = long
        self.geoloc = geoloc
        lastLogin = created_at
        self.setProfile
        self.save
    end
  
    def loginProfile
        self.lastLogin = DateTime.now
    end

    #######---------SAFE INFO------------------#######
    def safeInfo
        info = {}
        info["firstname"] = self.firstname
        info["lastname"]  = self.lastname
        info["propic"]    = self.propic
        info["email"]     = self.email
        info["id"]        = self.id
        info.to_json
    end
  
    #######---------INTERESTS HELPERS----------#######
    def setInterest(interest)
        self.interests << interest
        self.save
    end
  
    #TO DO: DELETE INTEREST
    def deleteInterest(interest)
  
    end
  
    #######---------FOLLOWERS HELPERS----------#######
    def getFollowers
        self.followers.count
    end
  
    def getFollowerPeople
        self.followers.all 
    end
  
    def getFollowed
        self.followed_people.count
    end
  
    def getFollowingPeople
        self.followed_people.all 
    end
  
    def follow(others)
        followed_people.concat(Array(others))
        self.save
        self
    end
  
    def unfollow(others)
        links_to_followed_people.all(:followed => Array(others)).destroy!
        self.reload
        self
    end
  
    #######--------RATING FUNCTIONS------------#######
    def addRatings(rating) 
        self.totalrating += rating
        self.totalrated += 1
    end
  
    def curTotRating
        if self.totalrated > 0
            (self.totalrating / self.totalrated)
        else
            0
        end
    end
  
    #######--------MESSAGE FUNCTIONS-----------########
  
    def getInbox
        self.inbox
    end
  
    def getSent
        self.sent
    end
  
    ########-------COURSE FUNCTIONS------------########
    def getStuClasses
        self.course_person.all(:type => "student").courses
    end
  
    def getTeachClasses
        self.course_person.all(:type => "teacher").courses
    end
  
    def becomingATeacher
        @teacher = true
    end
  
    ########-------PROFILE FUNCTIONS----------########
    def getProfile
        self.profile.slug
    end
  
    #### This is called when creating the person. No need to call this.
    def setProfile
        p = Profile.new
        p.slug = self.firstname + self.lastname
        self.profile = p 
        self.save
    end

end

class Profile
    include DataMapper::Resource
  
    property :id   , Serial, :key => true
    property :slug , String, :required => true 
  
    belongs_to :person 
end

class Courseprofile
    include DataMapper::Resource
  
    property :id   , Serial, :key => true
    property :slug , String, :required => true 
  
    belongs_to :course 
end

class Course
    include DataMapper::Resource

    property :id              , Serial,    :key => true
    property :slug            , String,    :default => lambda { | resource, prop| resource.title.downcase.gsub " ", "" }
    property :channel_name    , Text 
    property :title           , String,    :required => true
    property :date            , DateTime,  :required => true
    property :created_at      , DateTime   #This should be required.
    property :totstu          , Integer
    property :location        , String    
    property :coursepic       , String,    :length => 255
    property :description     , Text,      :required => true
    property :started         , Boolean,   :default => false
    property :lat             , Float
    property :long            , Float
    property :geoloc          , String
    
    ##################################################
    ####### ASSOCIATIONS #############################
    ##################################################
  
    ######------PERSON ASSOCIATION---------###########
    has n, :persons, :through => :course_person
  
    ######------COMMENTS ASSOCIATION---------#########
    has n, :comments, :order => :date.desc
  
    ######------interestS ASSOCIATION---------########
    has n, :interests, :through => Resource

    ######-----------CHAT ASSOCIATION---------########
    has 1, :chat     #, :through => Resource

    ######-----------COURSE PROFILE-----------########
    has 1, :courseprofile
  
    ##################################################
    ####### HELPER FUNCTIONS #########################
    ##################################################
  
    ######------BEFORE SAVE FUNCTION---------#########
    #TO DO: FIGURE OUT WHAT'S WRONG WITH THIS
    before :save do
       
    end
  
    def createCourse(title, description, location, date, totalstudent, coursepic, teacher, interest, lat, lng, geoloc)
        self.title = title
        self.date = date
        self.description = description
        self.totstu = totalstudent.to_i
        self.coursepic = coursepic
        self.created_at = DateTime.now
        self.location = location
        self.lat = lat.to_f
        self.long = lng.to_f
        self.geoloc = geoloc
        add_teacher teacher
        self.setInterest interest
        self.setProfile
        self.createChannelName
        self.save 
    end

    def updateCourse(title, description, location, date, totalstudent, coursepic, interest, lat, lng, geoloc)
        self.title = title
        self.date = date
        self.description = description
        self.totstu = totalstudent.to_i
        self.coursepic = coursepic
        self.created_at = DateTime.now
        self.location = location
        self.lat = lat
        self.lng = lng
        self.geoloc = geoloc
        self.setInterest interest
        self.createChannelName
        self.save 
    end

    def createChannelName
        self.channel_name = self.slug + self.date.strftime("%m-%d-%y")
    end

    #######---------PROFILE HELPERS----------#######
    def setProfile
        p = Courseprofile.new
        p.slug = self.slug
        self.courseprofile = p 
        self.save
    end
  
    #######---------INTERESTS HELPERS----------#######
    def setInterest(interest)
        if interest != nil && !self.interests.first(:keyword => interest)
            i = Interest.first(:keyword => interest)
            self.interests << i
            self.save
        end
    end
  
    #TO DO: DELETE INTEREST
    def deleteInterest(interest)
  
    end
  
    ######------COURSES WITHIN 10 DAYS---------#######
    def self.now
        all(:date.gt => DateTime.now-1, :date.lt => DateTime.now+10)
    end
  
    ######------STUDENTS IN THE COURSE---------#######
    def students
        self.course_person.all(:type => "student").persons
    end
  
    ######------TEACHER IN THE COURSE----------#######
    def teacher
        self.course_person.first(:type => "teacher").person
    end
  
    def teacherName
        self.course_person.first(:type => "teacher").person.firstname.capitalize + " " + self.course_person.first(:type => "teacher").person.lastname.capitalize
    end
  
    def teacherRating
        self.course_person.first(:type => "teacher").person.curTotRating
    end
  
    ######------ADD STUDENT TO COURSE---------########
    def add_student(person)
        c = CoursePerson.new type: "student"
        c.person = person
        self.course_person << c
        self.save 
    end
  
    ######------DELETE STUDENT FROM COURSE-----#######
    #TO DO - MAKE DELETION STUFF
    def delete_student(person)
        c = CoursePerson.first(:person_id => person.id, :course_id => self.id)
        # puts c.inspect
        if c 
            c.destroy!
            self.save
        else
            puts "wasn't a member"
        end 
    end
  
    ######------ADD TEACHER TO COURSE---------########
    def add_teacher(person)
        c = CoursePerson.new type: "teacher"
        c.person = person
        self.course_person << c
    end
  
    ######------DELETE TEACHER FROM COURSE-----#######
    #TO DO - MAKE DELETION STUFF - MORE COMPLICATED
    #MAYBE THIS WOULD DELETE THE COURSE AS WELL
    #def delete_teacher(person)
    #  c = CoursePerson.first(:person => person.id)
    #
    #end

    def classStart()
        ((self.date.strftime("%y") == DateTime.now.strftime("%y")) && 
        (self.date.strftime("%m") == DateTime.now.strftime("%m")) && 
        (self.date.strftime("%d") == DateTime.now.strftime("%d")) &&
        (self.date.strftime("%k").to_i + 1 >= DateTime.now.strftime("%k")).to_i)
    end

    ######-------CREATE CHAT CHANNEL---------#########
    def createChat()
        chat = Chat.new
        self.chat = chat
        self.chat.channel_name = self.createChannelName
        self.created_at = DateTime.now
        self.save
    end 

    def addRemark(channel, person, text)
        if channel == self.createChannelName && person
            r = Remark.new
            r.createRemark person, text
            self.chat.remarks << r 
            self.chat.save
        else
            puts "for some reason it didn't make it"
            false
        end
    end

end

class Comment
    include DataMapper::Resource
  
    property :id      , Serial, :key => true
    property :bodytext, Text,    :required => true
    property :date    , DateTime,:required => true 
  
    belongs_to :course
    belongs_to :person
  
    def makeComment(bodytext, person, course)
        self.course = course
        self.person = person
        self.bodytext = bodytext
        self.date = DateTime.now
        course.comments << self
        person.comments << self
        self.save
    end

end

class Message
    include DataMapper::Resource
  
    property :id      , Serial 
    property :subject , String  , :required => true
    property :bodytext, Text
    property :created_at, DateTime
  
    belongs_to :source, 'Person', :key => true
    belongs_to :target, 'Person', :key => true
  
    #TO DO: I NEED TO FIX THE INBOX
    def sendMail(sender, receiver)
        self.source = sender
        sender.sent << self
        self.target = receiver
        receiver.inbox << self
        self.created_at = DateTime.now
        self.save
    end

end

class Interest
    include DataMapper::Resource
  
    property :id       , Serial, :key => true
    property :keyword  , String
  
    has n, :topics , :required => false
    has n, :persons , :through => Resource
    has n, :courses , :through => Resource

end

class Topic
    include DataMapper::Resource

    property :keyword   , String,   :key => true, :unique_index => true

    belongs_to :interest

end

class Chat
    include DataMapper::Resource

    property :id            , Serial  , :key => true
    property :channel_name  , String
    property :created_at    , DateTime
    property :finished_at   , DateTime

    belongs_to  :course     
    has n,      :remarks    

    

end

class Remark
    include DataMapper::Resource

    property :id           , Serial  , :key => true
    property :statement    , String  , :length => 300
    property :created_at   , DateTime
    property :person_id    , Integer
    property :person_first , String
    property :person_last  , String

    belongs_to :chat  

    def createRemark(p, text)
        self.statement = text
        self.created_at = DateTime.now
        self.person_id = p.id
        self.person_first = p.firstname
        self.person_last = p.lastname
    end  
    
end

DataMapper.finalize
# DataMapper.auto_migrate!
DataMapper.auto_upgrade!
