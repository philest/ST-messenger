echo "Removing Gemfile.lock..."
rm Gemfile.lock
echo "Switching to JRuby..."
rvm use jruby@birdv
echo "Bundle install..."
bundle install
branch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
echo "Committing current version to git..."
git add --all
read -p "commit message: " commit_message
git commit -m "${commit_message}"
echo "Pushing to 'origin-${branch}'"
git push origin $branch
echo "Switching back to CRuby..."
rvm use default
echo "Done."