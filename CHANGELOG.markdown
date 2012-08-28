Changelog
=========

1.1.7 (Current version)
-----------------------
* Fix #50, a method that was forgotten to time during the ignoreable => ignorable typo update

1.1.6
-----
* Minor code cleanup for my benefit

1.1.5
-----
* Fix #47, a problem where models could not recommend themselves

1.1.4
-----
* Fix #41, a problem where Resque rake tasks were required regardless of whether or not it was bundled
* Fix #46 by adding UniqueJob middleware for Sidekiq.
* Added caches for an item's number of likes and dislikes received

1.1.3
-----
* Update Redis.

1.1.2
-----
* Fix #38, a problem with enqueueing users based on updating the score of a recommendable record

1.1.1
-----
* Support for Sidekiq, Resque, DelayedJob and Rails::Queueing (issue #28)
  * You must manually bundle Sidekiq, Resque, or DelayedJob. Rails::Queueing is available as a fallback for Rails 4.x
* Use [apotonick/hooks](https://github.com/apotonick/hooks) to implement callbacks (issue #25). See the [detailed README](http://davidcelis.com/recommendable) for more info on usage.

1.0.0
-----
* Dynamic finders now return ActiveRecord::Relations! This means you can chain other ActiveRecord query methods like so:

```ruby
current_user.recommended_posts.where(:category => "technology")
current_user.liked_movies.limit(10)
current_user.stashed_books.where(:author => "Cormac McCarthy")
current_user.disliked_shows.joins(:cast_members).where('cast_members.name = Kim Kardashian')
```

* You can now specify a count for `User#recommendations`:

```ruby
current_user.recommendations(10)
```

* Bug fixes

0.2.0
-----
* NOTE: This release is NOT backwards compatible. Please migrate your databases:

```
rename_column :recommendable_ignores, :ignoreable_id, :ignorable_id
rename_column :recommendable_ignores, :ignoreable_type, :ignorable_type
rename_table  :recommendable_stashed_items, :recommendable_stashes
```

* Fix an issue with recommendable models implemented via STI 
* Fix a library-wide typo of "ignoreable" to "ignorable"

0.1.9
-----
* Yanked due to breaking bug

0.1.8
-----
* Revert changes made in 0.1.7 due to licensing

0.1.7
-----
* Yanked and no longer available.
* Attempted switch from Resque to Sidekiq

0.1.6
-----
* Dynamic finders for your User class:

`current_user.liked_movies`
`current_user.disliked_shows`
`current_user.recommended_movies`

* Implement sorting of recommendable models:

``` ruby
>> Movie.top(5)
=> [#<Movie id: 14>, #<Movie id: 15>, #<Movie id: 13>, #<Movie id: 12>, #<Movie id: 11>]
>> Movie.top
=> #<Movie id: 14>
```

* Bugfix: users/recommendable objects will now be removed from Redis upon being destroyed

0.1.5
-----
* Major bugfix: similarity values were, incorrectly, being calculated as 0.0 for every user pair. Sorry!
* The tables for all models are now all prepended with "recommendable_" to avoid possible collision. If upgrading from a previous version, please do the following:

``` bash
$ rails g migration RenameRecommendableTables
```

And paste this into your new migration:

``` ruby
class RenameRecommendableTables < ActiveRecord::Migration
  def up
    rename_table :likes,         :recommendable_likes
    rename_table :dislikes,      :recommendable_dislikes
    rename_table :ignores,       :recommendable_ignores
    rename_table :stashed_items, :recommendable_stashed_items
  end

  def down
    rename_table :recommendable_likes,         :likes
    rename_table :recommendable_dislikes,      :dislikes
    rename_table :recommendable_ignores,       :ignores
    rename_table :recommendable_stashed_items, :stashed_items
  end
end
```

0.1.4
-----
* `acts_as_recommendable` is no longer needed in your models
* Instead of declaring `acts_as_recommended_to` in your User class, please use `recommends` instead, passing in a list of your recommendable models as a list of symbols (e.g. `recommends :movies, :books`)
* Your initializer should no longer declare the user class. This is no longer necessary and is deprecated.
* Fix an issue that caused the unnecessary need for eager loading models in development
* Removed aliases: `liked_records`, `liked_records_for`, `disliked_records`, and `disliked_records_for`
* Renamed methods:
  * `has_ignored?` => `ignored?`
  * `has_stashed?` => `stashed?`
* Code quality tweaks

0.1.3 (current version)
-----------------------

* Improvements to speed of similarity calculations.
* Added an instance method to items that act_as_recommendable, `rated_by`. This returns an array of users that like or dislike the item.

0.1.2
-----

* Fix an issue that could cause similarity values between users to be incorrect.
* `User#common_likes_with` and `User#common_dislikes_with` now return the actual Model instances by default. Accordingly, these methods are no longer private.

0.1.1
-----
* Introduce the "stashed item" feature. This gives the ability for users to save an item in a list to try later, while at the same time removing it from their list of recommendations. This lets your users keep getting new recommendations without necessarily having to rate what they know they want to try.

0.1.0
-----
* Welcome to recommendable!
