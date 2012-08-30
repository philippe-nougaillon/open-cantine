# encoding: utf-8

module ApplicationHelper

 def format_date(date)
      lesmois = ['janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre']
      lesjours = ['lundi','mardi','mercredi',"jeudi",'vendredi','samedi','dimanche']
      j = lesjours[date.wday.to_i - 1]
      jour=date.day.to_s
      mois=lesmois[date.month.to_i - 1]
      annee=date.year.to_s
      return sprintf('%s %s %s %s',j,jour,mois,annee)
  end 

  def format_mois(mois)
      lesmois = ['janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre']
      return lesmois[mois - 1]
  end

  # Request from an iPhone or iPod touch? (Mobile Safari user agent)
  def iphone_user_agent?
    request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/(Mobile\/.+Safari)/]
  end

  def avatar_url(user)
	gravatar_id = Digest::MD5.hexdigest(user.username.downcase)
	"http://gravatar.com/avatar/#{gravatar_id}.png?s=25"
  end

  def google_analytics_js 
	%(<script type="text/javascript"> var _gaq = _gaq || []; _gaq.push(['_setAccount', 'UA-23235074-1']); _gaq.push(['_trackPageview']); (function() { var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true; ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js'; var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s); })(); </script>)

  end

end
