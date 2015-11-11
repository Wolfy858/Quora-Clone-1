require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')

    self.results_as_hash = true
    self.type_translation = true
  end
end

class User
  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM users')
    results.map { |result| User.new(result) }
  end

  def self.find_by_id(num)
    #QuestionsDatabase.instance.get_first_row will return only the first row hash.
    #can be used instead of execute.
    data = QuestionsDatabase.instance.execute(<<-SQL, num)
      SELECT *
      FROM users
      WHERE id = (?)
    SQL

    User.new(data.first)
  end

  def self.find_by_name(first, last)
    data = QuestionsDatabase.instance.execute(<<-SQL, first: first, last: last)
      SELECT *
      FROM users
      WHERE fname = :first AND lname = :last
    SQL

    User.new(data.first)
  end

  attr_accessor :id, :fname, :lname

  def initialize(options)
    @id, @fname, @lname = options.values_at('id', 'fname', 'lname')
  end

  def create
    raise 'already exists in db!' unless @id.nil?

    QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      INSERT INTO
        users(fname, lname)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end
end

class Question
  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM questions')
    results.map { |result| Question.new(result) }
  end

  def self.find_by_author_id(num)
    data = QuestionsDatabase.instance.execute(<<-SQL, num)
      SELECT *
      FROM questions
      WHERE author_id = (?)
    SQL

    User.new(data.first)
  end

  attr_accessor :id, :title, :body, :author_id

  def initialize(options)
    @id, @title, @body, @author_id =
      options.values_at('id', 'title', 'body', 'author_id')
  end

  def create
    raise 'already exists in db!' unless @id.nil?

    QuestionsDatabase.instance.execute(<<-SQL, title, body, author_id)
      INSERT INTO
        questions(title, body, author_id)
      VALUES
        (?, ?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end
end

class Reply

  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM replies')
    results.map { |result| Reply.new(result) }
  end

  attr_accessor :id, :question_id, :parent_reply_id, :reply_author_id,
                :body

  def  initialize(options)
    @id, @question_id, @parent_reply_id, @reply_author_id, @body =
      options.values_at('id', 'question_id', 'parent_reply_id',
      'reply_author_id', 'body')
  end

  def attributes
    {
      question_id: @question_id,
      parent_reply_id: @parent_reply_id,
      reply_author_id: @reply_author_id,
      body: @body
    }
  end


  def create
    raise 'GET OUTTA HERE' unless @id.nil?

    QuestionsDatabase.instance.execute(<<-SQL, attributes)
      INSERT INTO
        replies(question_id, parent_reply_id, reply_author_id, body)
      VALUES
        (:question_id, :parent_reply_id, :reply_author_id, :body)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end
end
