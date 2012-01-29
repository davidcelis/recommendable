recommendable
=============

Recommendable is a Rails Engine to add Like/Dislike functionality to your 
application. It uses Redis to generate recommendations quickly through a
collaborative filtering algorithm that I modified myself. Your users' tastes
are compared with one another and used to give them great recommendations!
Yes, Redis is required. Scroll to the end of the README for more info on that.

Why Likes and Dislikes?
-----------------------

[This is why][0]!

Binary voting habits are most certainly not an odd phenomenon. People tend to
vote in only two different ways. Some folks give either 1 star or 5 stars. Some
people fluctuate between 3 and 4 stars. There are always outliers, but what it
comes down to is this: a person's binary votes indicate, in general, a dislike
or like of what they're voting on. I'm just giving the people what they want.

Installation
------------

Add the following to your Rails application's `Gemfile`:

``` ruby
  gem "recommendable"
```

After your `bundle install`, you can then run:

    $ rails g recommendable:install (--user-class=User)

After running the installation generator, you should double check
`config/initializers/recommendable.rb` for options on configuring your Redis
connection.

Finally, Recommendable uses Resque to place users in a queue. Users must wait
their turn to regenerate recommendations so that your application does not get
throttled. Don't worry, though! Most of the time, your users will barely have
to wait. In fact, you can run multiple resque workers if you wish.

Assuming you have `redis-server` running...

    $ QUEUE=recommendable rake environment resque:work

You can run this command multiple times if you wish to start more than one
worker. This is the standard rake task for starting a Resque worker so, for
more options on this task, head over to [defunkt/resque][1]

Usage
-----

In your Rails model that represents your application's user:

``` ruby
class User < ActiveRecord::Base
  acts_as_recommended_to
  
  # ...
end
```

Then, from any Rails model you wish your `user` to be able to `like` or `dislike`:

``` ruby
class Movie < ActiveRecord::Base
  acts_as_recommendable
  
  # ...
end

class Show < ActiveRecord::Base
  acts_as_recommendable
  
  # ...
end
````

And that's it!

### Liking/Disliking

At this point, your user will be ready to `like` movies...

``` ruby
current_user.like Movie.create(:title => '2001: A Space Odyssey', :year => 1968)
#=> true
```

... or `dislike` them:

``` ruby
current_user.dislike Movie.create(:title => 'Star Wars: Episode I - The Phantom Menace', :year => 1999)
#=> true
```

In addition, several helpful methods are available to your user now:

``` ruby
current_user.likes? Movie.find_by_title('2001: A Space Odyssey')
#=> true
current_user.dislikes? Movie.find_by_title('Star Wars: Episode I - The Phantom Menace')
#=> true
other_movie = Movie.create('Back to the Future', :year => 1985)
current_user.dislikes? other_movie
#=> false
current_user.like other_movie
#=> true
current_user.liked_records
#=> [#<Movie name: '2001: A Space Odyssey', year: 1968>, #<Movie name: 'Back to the Future', :year => 1985>]
current_user.disliked_records
#=> [#<Movie name: 'Star Wars: Episode I - The Phantom Menace', year: 1999>]
```

Because you are allowed to declare multiple models as recommendable, you may
wish to return a set of liked or disliked objects for only one of those
models.

``` ruby
current_user.liked_records_for(Movie)
#=> [#<Movie name: '2001: A Space Odyssey', year: 1968>, #<Movie name: 'Back to the Future', :year => 1985>]
current_user.disliked_records_for(Show)
#=> []
```

### Ignoring

If you want to give your user the ability to `ignore` recommendations or even
just hide stuff on your website that they couldn't care less about, you can!

``` ruby
weird_movie_nobody_wants_to_watch = Movie.create(:title => 'Cool World', :year => 1998)
current_user.ignore weird_movie_nobody_wants_to_watch
#=> true
current_user.ignored_records
#=> [#<Movie name: 'Cool World', year: 1998>]
current_user.ignored_records_for(Show)
#=> []
```

Do what you will with this list of records. The power is yours.

### Unliking/Undisliking/Unignoring

Note that liking a movie that has already been disliked (or vice versa) will
simply destroy the old rating and create a new one. If a user attempts to `like`
a movie that they already like, however, nothing happens and `nil` is returned.
If you wish to manually remove an item from a user's likes or dislikes or
ignored records, you can:

``` ruby
current_user.like Movie.create(:title => 'Avatar', :year => 2009)
#=> true
user.unlike Movie.find_by_title('Avatar')
#=> true
user.liked_records
#=> []
```

You can use `undislike` and `unignore` in the same fashion. So, as far as the Likes
and Dislikes go, do you think that's enough? Because I didn't.

``` ruby
friend = User.create(:username => 'joeblow')
awesome_movie = Movie.find_by_title('2001: A Space Odyssey')
friend.like awesome_movie
#=> true
awesome_movie.liked_by
#=> [#<User username: 'davidcelis'>, #<User username: 'joeblow'>]
Movie.find_by_title('Star Wars: Episode I - The Phantom Menace').disliked_by
#=> [#<User username: 'davidcelis'>]
```

Recommendations
---------------

When a user submits a new `Like` or `Dislike`, they enter a queue to have their
recommendations refreshed. Once that user exits the queue, you can retrieve
these like so:

``` ruby
current_user.recommendations
#=> [#<Movie highly_recommended>, #<Show somewhat_recommended>, #<Movie meh>]
current_user.recommendations_for(Show)
#=> [#<Show somewhat_recommended>]
```

The top recommendations are returned in an array ordered by how good recommendable
believes the recommendation to be (from best to worst).

``` ruby
current_user.like somewhat_recommended_show
#=> true
current_user.recommendations
#=> [#<Movie highly_recommended>, #<Movie meh>]
```
  
Finally, you can also get a list of the users found to be most similar to your
current user:

``` ruby
current_user.similar_raters
#=> [#<User username: 'joe-blow'>, #<User username: 'less-so-than-joe-blow']
```

Likewise, this list is ordered from most similar to least similar.

Documentation
-------------

Some of the above methods are tweakable with options. For example, you can
adjust the number of recommendations returned to you (the default is 10) and
the number of similar uses returned (also 10). To see these options, check
the documentation.

A note on Redis
---------------

Recommendable currently depends on [Redis](http://redis.io/). It will install 
the redis-rb gem as a dependency, but you must install Redis and run it
yourself. Also note that your Redis database must be persistent. Recommendable
will use Redis to permanently store sorted sets to quickly access recommendations.
Please take care with your Redis database! Fortunately, if you do lose your
Redis database, there's hope (more on that later).

Installing Redis
----------------

Recommendable requires Redis to deliver recommendations. Why? Because my
collaborative filtering algorithm is based almost entirely on set math, and
Ruby's Set class just won't cut it for fast recommendations.

### Homebrew

For Mac OS X users, homebrew is by far the easiest way to install Redis.

    $ brew install redis
    $ redis-server /usr/local/etc/redis.conf

You should now have Redis running as a daemon on localhost:6379

### Via Resque

Resque (which is also a dependency of recommendable) includes Rake tasks that
will install and run Redis for you:

    $ git clone git://github.com/defunkt/resque.git
    $ cd resque
    $ rake redis:install dtach:install
    $ rake redis:start

If you do not have admin rights to your machine:

    $ git clone git://github.com/defunkt/resque.git
    $ cd resque
    $ PREFIX=<your_prefix> rake redis:install dtach:install
    $ rake redis:start

Redis will now be running on localhost:6379. After a second, you can hit `ctrl-\`
to detach and keep Redis running in the background.

(Thanks to [defunkt][1] for mentioning this
method, and thanks to [ezmobius][2] for
making it possible)

Manually regenerating recommendations
-------------------------------------

If a catastrophe occurs and your Redis database is either destroyed or rendered
unusable in some other way, there is hope. You can run the following from your
application's console (assuming your user class is User):

    User.all.each do |user|
      user.update_similarities
      user.update_recommendations
    end

But please try not to have to do this manually!

Contributing to recommendable
-----------------------------
 
Read the [Contributing][3] wiki page first. 

Once you've made your great commits:

1. [Fork][4] recommendable
2. Create a feature branch
3. Write your code (and tests please)
4. Push to your branch's origin
5. Create a [Pull Request][5] from your branch
6. That's it!

Links
-----
* Code: `git clone git://github.com/davidcelis/recommendable.git`
* Home: <http://github.com/davidcelis/recommendable>
* Docs: <http://rubydoc.info/gems/recommendable/0.1.0/frames>
* Bugs: <http://github.com/davidcelis/recommendable/issues>
* Gems: <http://rubygems.org/gems/recommendable>

Copyright
---------

Copyright © 2012 David Celis. See LICENSE.txt for
further details.

[0]: http://youtube-global.blogspot.com/2009/09/five-stars-dominate-ratings.html
[1]: https://github.com/defunkt/resque
[2]: https://github.com/ezmobius/redis-rb
[3]: http://wiki.github.com/defunkt/resque/contributing
[4]: http://help.github.com/forking/
[5]: http://help.github.com/pull-requests/
