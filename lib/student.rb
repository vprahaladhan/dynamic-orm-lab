require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'interactive_record.rb'

class Student < InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    column_names = [] 
    sql = "PRAGMA table_info('#{table_name}')"
    DB[:conn].execute(sql).each {|column| column_names << column["name"]}
    column_names
  end

  def self.find_by_name(name)
    students = []
    DB[:conn].execute("SELECT * FROM #{table_name} WHERE name = '#{name}'").each do |student|
      students << student.delete_if {|key, value| Float(key) != nil rescue false}
    end
    students
  end

  def self.find_by(search_key)
    students = []
    search_str = ''

    search_key.each do |key, value|
      search_str += "#{key.to_s} = "
      search_str += ((Float(value) != nil rescue false) ? "#{value}" : "'#{value}'")
    end

    DB[:conn].execute("SELECT * FROM #{table_name} WHERE #{search_str}").each do |student|
      students << student.delete_if {|key, value| Float(key) != nil rescue false}
    end
    students
  end

  self.column_names.each do |column|
    attr_accessor column.to_sym
  end  
  
  def initialize(options = {})
    options.each {|key, value| self.send("#{key}=", value)}
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|name| name == 'id'}.join(", ")
  end

  def values_for_insert
    values = []
    columns = self.class.column_names.delete_if {|name| name == 'id'}
    columns.each {|name| values << "'#{self.send(name)}'"}
    values.join(", ")
  end

  def save
    DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})")
    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def numeric?
    Float(self) != nil rescue false
  end
end