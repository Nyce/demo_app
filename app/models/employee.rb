class Employee < ActiveRecord::Base
  attr_accessible :Name, :Pay_Basis, :Position_Title, :Salary, :Status
end
