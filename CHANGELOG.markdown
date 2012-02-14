Changelog
=========

0.1.5 (current version)
-----------------------
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
