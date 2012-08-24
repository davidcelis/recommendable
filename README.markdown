# Recommendable [![Build Status](https://secure.travis-ci.org/davidcelis/recommendable.png)](http://travis-ci.org/davidcelis/recommendable)

Recommendable is an engine for Rails 3 applications to quickly add the ability for your users to Like/Dislike items and receive recommendations for new items. It uses Redis to store your recommendations and keep them sorted by how good the recommendation is.

Requirements
------------
* Ruby 1.9.x
* Rails 3.x or 4.x
* Sidekiq or Resque (or DelayedJob)

Bundling one of the queueing systems above is highly recommended to avoid having to manually refresh users' recommendations. If running on Rails 4, the built-in queueing system is supported. If you bundle [Sidekiq][sidekiq], [Resque][resque], or [DelayedJob][delayed_job], Recommendable will use your bundled queueing system instead. If bundling Resque, you should also include ['resque-loner'][resque-loner] in your Gemfile to ensure your users only get queued once (Sidekiq does this by default, and there is no current way to avoid duplicate jobs in DelayedJob).

Installation
------------

Add the following to your Rails application's `Gemfile`:

``` ruby
  gem 'recommendable'
```

After bundling, run the installation generator:

``` bash
$ rails g recommendable:install
```

Double check `config/initializers/recommendable.rb` for options on configuring your Redis connection. After a user likes or dislikes something new, they are placed in a queue to have their recommendations updated. If you're using the basic Rails 4.0 queue, you don't need to do anything explicit. If using Sidekiq, Resque, or DelayedJob, start your workers from the command line:

``` bash
# sidekiq
$ bundle exec sidekiq -q recommendable
# resque
$ QUEUE=recommendable rake environment resque:work
# delayed_job
$ rake jobs:work
```

Usage
-----

In your Rails model that will be receiving recommendations:

``` ruby
class User < ActiveRecord::Base
  recommends :movies, :shows, :other_things
  
  # ...
end
```

That's it! Please note, however, that you may only do this in one model at this time.

For more details on how to use Recommendable once it's installed and configured, [check out the more detailed README][recommendable] or see the [documentation][documentation].

Installing Redis
----------------

Recommendable requires Redis to deliver recommendations. The collaborative filtering logic is based almost entirely on set math, and Redis is blazing fast for this. _NOTE: Your redis database MUST be persistent._

### Mac OS X

For Mac OS X users, homebrew is by far the easiest way to install Redis. Make sure to read the caveats after installation!

``` bash
$ brew install redis
```

### Linux

For Linux users, there is a package on apt-get.

``` bash
$ sudo apt-get install redis-server
$ redis-server
```

Redis will now be running on localhost:6379. After a second, you can hit `ctrl-\` to detach and keep Redis running in the background.

### Redis problems?

Oops, did you kill your Redis database? Not to worry. Likes, Dislikes, Ignores,
and StashedItems are stored as models in your regular database. As long as these
still exist, you can regenerate the similarity values and recommendations on the
fly. But try not to have to do it!

``` ruby
Users.all.each do |user|
  user.send :update_similarities
  user.send :update_recommendations
end
```

Why not stars?
--------------
I'll let Randall Munroe of [XKCD](http://xkcd.com/) take this one for me:

[![I got lost and wandered into the world's creepiest cemetery, where the headstones just had names and star ratings. Freaked me out. When I got home I tried to leave the cemetery a bad review on Yelp, but as my hand hovered over the 'one star' button I felt this distant chill ...](http://imgs.xkcd.com/comics/star_ratings.png)](http://xkcd.com/1098/)

Contributing to recommendable
-----------------------------

Once you've made your great commits:

1. [Fork][forking] recommendable
2. Create a feature branch
3. Write your code (and tests please)
4. Push to your branch's origin
5. Create a [Pull Request][pull requests] from your branch
6. That's it!

Links
-----
* Code: `git clone git://github.com/davidcelis/recommendable.git`
* Home: <http://github.com/davidcelis/recommendable>
* Docs: <http://rubydoc.info/gems/recommendable/frames>
* Bugs: <http://github.com/davidcelis/recommendable/issues>
* Gems: <http://rubygems.org/gems/recommendable>

Copyright
---------

Copyright © 2012 David Celis. See LICENSE.txt for
further details.

[stars]: http://davidcelis.com/blog/2012/02/01/why-i-hate-five-star-ratings/
[sidekiq]: https://github.com/mperham/sidekiq
[delayed_job]: https://github.com/tobi/delayed_job
[resque]: https://github.com/defunkt/resque
[resque-loner]: https://github.com/jayniz/resque-loner
[forking]: http://help.github.com/forking/
[pull requests]: http://help.github.com/pull-requests/
[collaborative filtering]: http://davidcelis.com/blog/2012/02/07/collaborative-filtering-with-likes-and-dislikes/
[recommendable]: http://davidcelis.github.com/recommendable/
[documentation]: http://rubydoc.info/gems/recommendable/frames
