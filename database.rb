DataMapper::setup(:default, ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite")

DataMapper::Model.raise_on_save_failure = true

class Person
  include DataMapper::Resource
  include BCrypt
  
  property :id            , Serial
  property :firstname     , String  , :required => true, :length => 255
  property :lastname      , String  , :required => true, :length => 255
  property :email         , String  , :required => true, :length => 255
  property :password      , BCryptHash
  property :teacher       , Boolean , :default => false
  property :propic        , String  , :length => 255, :default => "http://critterapp.pagodabox.com/img/user.jpg"
  #we need to implement this.
  property :like          , Integer 
  property :interest1     , String  , :length => 255
  property :interest2     , String  , :length => 255
  property :interest3     , String  , :length => 255
  property :interest4     , String  , :length => 255

  #belongs_to :courses     , :required => false

  has n, :courses, :through => Resource

  before :save do
    self.email = self.email.downcase
  end

  def becomingATeacher
    @teacher = true
  end

end


class Course
  include DataMapper::Resource

  property :slug            , String,    :key => true, :unique_index => true, :default => lambda { | resource, prop| resource.title.downcase.gsub " ", "-" }
  property :title           , String,    :required => true
  property :date            , DateTime,  :required => true
  property :totstu          , String,    :required => false
  property :location        , String,    :required => false
  property :instructorfirst , String,    :required => true
  property :instructorlast  , String,    :required => true
  property :description     , Text,      :required => true
  property :interest        , String,    :required => false
  
  
  has n, :persons, :through => Resource

  def self.now
      all(:date.gt => DateTime.now, :date.lt => DateTime.now+10)
  end

  def attending(student)

  end

end

DataMapper.finalize
DataMapper.auto_upgrade!
