task :rehash_users => :environment do
	@users = User.all
	@users.each do | u |
		u.password= u.password_hash
		u.save
		puts u.password_hash
	end
end

