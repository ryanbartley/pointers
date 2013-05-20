post '/ajax/follow' do

	postinfo = params['postinfo']

	pfollowed = getPersonFromProfile postinfo['profile']
	pfollowing = Person.first(:email => postinfo['myemail'])

	data = {}

	postinfo.each do |info|
		puts info
	end

	if pfollowed.id != pfollowing.id
		if postinfo['following'] == "false"
			if pfollowing.follow pfollowed
				puts "they are now following"
				data['following'] = true
				data['me'] = false
				data['notfollowing'] = false
			end
		else 
			if pfollowing.unfollow pfollowed
				puts "they are not following"
				data['notfollowing'] = true
				data['following'] = false
				data['me'] = false
			end
		end
	else
		data['following'] = false
		data['me'] = true
		data['notfollowing'] = false
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
	peopleImFollowing = following.getFollowingPeople
	peopleImFollowing.each do |person|
		if person.id == followed.id
			return true
		end
	end
	return false
end

