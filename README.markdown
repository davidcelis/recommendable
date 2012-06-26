# Recommendable [![Build Status](https://secure.travis-ci.org/davidcelis/recommendable.png)](http://travis-ci.org/davidcelis/recommendable)

Recommendable is an engine for Rails 3 applications to quickly add the ability for your users to Like/Dislike items and receive recommendations for new items. It uses Redis to store your recommendations and keep them sorted by how good the recommendation is.

Requirements
------------
* Ruby 1.9.2 (1.9.x if using from git. May run on 1.8.7, I don't know)
* Rails 3.x

Installation
------------

Add the following to your Rails application's `Gemfile`:

``` ruby
  gem "recommendable", :git => "git://github.com/davidcelis/recommendable"
```

After bundling, run the installation generator:

``` bash
$ rails g recommendable:install
```

Double check `config/initializers/recommendable.rb` for options on configuring your Redis connection. After a user likes or dislikes something new, they are placed in a Resque queue to have their recommendation updated. Start up resque like so:

``` bash
$ QUEUE=recommendable rake environment resque:work
```

You can run this command multiple times if you wish to start more than one
worker. For more options on this task, head over to [defunkt/resque][resque].

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

### Homebrew

For Mac OS X users, homebrew is by far the easiest way to install Redis.

``` bash
$ brew install redis
```

### Via Resque

Resque (which is also a dependency of recommendable) includes Rake tasks that
will install and run Redis for you:

``` bash
$ git clone git://github.com/defunkt/resque.git
$ cd resque
$ rake redis:install dtach:install
$ rake redis:start
```

Redis will now be running on localhost:6379. After a second, you can hit `ctrl-\` to detach and keep Redis running in the background.

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
[resque]: https://github.com/defunkt/resque
[forking]: http://help.github.com/forking/
[pull requests]: http://help.github.com/pull-requests/
[collaborative filtering]: http://davidcelis.com/blog/2012/02/07/collaborative-filtering-with-likes-and-dislikes/
[recommendable]: http://davidcelis.github.com/recommendable/
[documentation]: http://rubydoc.info/gems/recommendable/frames
