require 'pry'
class Dog
    attr_accessor :name, :breed
    attr_reader :id

    def initialize(name:, breed:, id: nil)
        @name = name
        @breed = breed
        @id = id
    end

    def save
        return self.update if self.id
        sql = <<-SQL
            INSERT INTO dogs(name, breed)
            VALUES(?, ?);
        SQL

        DB[:conn].execute(sql, self.name, self.breed)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]

        self.class.new(name: self.name, breed: self.breed, id: self.id)
    end

    def update
        sql = <<-SQL
            UPDATE dogs
            SET name = ?, breed = ?
            WHERE id = ?
        SQL

        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end

    def self.create(attr)
        new_dog = self.new(attr)
        new_dog.save
        new_dog
    end

    def self.create_table
        sql = <<-SQL
            CREATE TABLE dogs(
                id INTEGER PRIMARY KEY,
                name TEXT,
                breed TEXT
            );
        SQL

        DB[:conn].execute(sql)
    end

    def self.find_by_id(id)
        DB[:conn].execute("SELECT * FROM dogs WHERE id = #{id}").map do |row|
            self.new_from_db(row)
        end.last
    end

    def self.new_from_db(row)
        self.create({id: row[0], name: row[1], breed: row[2]})
    end

    def self.drop_table
        DB[:conn].execute('DROP TABLE dogs;')
    end

    def self.find_or_create_by(name:, breed:)
        sql = <<-SQL
            SELECT * FROM dogs WHERE name = ? AND breed = ?;
        SQL
        
        var = DB[:conn].execute(sql, name, breed)

        if !var.empty?
            var = self.new(name: name, breed: breed, id: var[0][0])
        else
            var = self.create({name: name, breed: breed})
        end
        var
    end

    def self.find_by_name(name)
        sql = <<-SQL
            SELECT * FROM dogs 
            WHERE name = ?;
        SQL

        self.new_from_db(DB[:conn].execute(sql, name)[0])
    end
end