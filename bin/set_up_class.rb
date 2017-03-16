require_relative("./local.rb")


school = School.create(signature: "ST Prep", name: "STP", code: "test|test-es")

teacher = Teacher.create(signature: "Mr. McPeek", email: "david.mcpeek@yale.edu")

school.signup_teacher(teacher)