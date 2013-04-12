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
  property :instructorfirst , String,    :required => true
  property :instructorlast  , String,    :required => true
  property :description     , Text,      :required => true
  
  
  has n, :persons, :through => Resource

  def attending(student)

  end

end

DataMapper.finalize
DataMapper.auto_upgrade!
