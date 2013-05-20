post '/ajax/follow' do

	postinfo = params['postinfo']

	pfollowed = getPersonFromProfile postinfo['profile']
	pfollowing = Person.first(:email => postinfo['myemail'])

	data = {}

	if pfollowed == pfollowing
		if checkFollowing
			data['following'] = pfollowing.follow pfollowed
		else
			
		end
	else

	end

	result = {'activity' => data, 'status' => "OK"}

	result.to_json
end

get '/ajax/courseloc' do
    @courses = Course.now
    courses = {}

    @courses.each do |course|
    	courses[course.title] = {"loc" => course.geoloc, "id" => course.id, 
    		"slug" => course.courseprofile.slug, "date" => course.date.strftime("%m/%d/%y"), 
    		"totstu" => course.totstu - course.students.count, 
    		"lat" => course.lat, "long" => course.long, "desc" => course.description }
    end

    result = {'courses' => courses, 'status' => "OK"}

    result.to_json
end

def getPersonFromProfile(slug)
    Person.first(:id => Profile.first(:slug => slug).person_id)
end

def checkFollowing(following, followed)

end

