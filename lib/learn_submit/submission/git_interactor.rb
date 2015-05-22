module LearnSubmit
  class Submission
    class GitInteractor
      attr_reader   :username, :git, :message
      attr_accessor :remote_name, :old_remote_name, :old_url

      LEARN_ORG_NAMES = [
        'learn-co',
        'learn-co-curriculum',
        'learn-co-students'
      ]

      def initialize(username:, message:)
        @username = username
        @message  = message || 'Done.'
        @git      = set_git
      end

      def commit_and_push
        check_remote
        add_changes
        commit_changes

        push!
      end

      def repo_name
        url = git.remote(remote_name).url
        url.match(/^.+\w+\/(.*?)(?:\.git)?$/)[1]
      end

      def branch_name
        git.branch.name
      end

      private

      def set_git
        begin
          Git.open(FileUtils.pwd)
        rescue ArgumentError => e
          if e.message.match(/path does not exist/)
            puts "It doesn't look like you're in a lesson directory."
            puts 'Please cd into an appropriate directory and try again.'

            exit
          else
            puts 'Sorry, something went wrong. Please try again.'
            exit
          end
        end
      end

      def check_remote
        self.remote_name = if git.remote.url.match(/#{username}/).nil?
          fix_remote!
        else
          git.remote.name
        end
      end

      def fix_remote!
        self.old_remote_name = git.remote.name
        self.old_url         = git.remote.url

        add_backup_remote
        remove_old_remote
        add_correct_remote
      end

      def add_backup_remote
        git.add_remote("#{old_remote_name}-bak", old_url)
      end

      def remove_old_remote
        git.remote(old_remote_name).remove
      end

      def add_correct_remote
        new_url = old_url.gsub(/#{LEARN_ORG_NAMES.join('|').gsub('-','\-')}/, username)
        git.add_remote(old_remote_name, new_url)

        old_remote_name
      end

      def add_changes
        puts 'Adding changes...'
        git.add(all: true)
      end

      def commit_changes
        puts 'Committing changes...'
        begin
          git.commit(message)
        rescue Git::GitExecuteError => e
          if e.message.match(/nothing to commit/)
            puts "It looks like you have no changes to commit. Will still try updating your submission..."
          else
            puts 'Sorry, something went wrong. Please try again.'
            exit
          end
        end
      end

      def push!
        puts 'Pushing changes to github...'
        push_remote = git.remote(self.remote_name)
        git.push(push_remote)
      end
    end
  end
end
