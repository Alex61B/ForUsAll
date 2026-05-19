FactoryBot.define do
  factory :time_off_request do
    association :user
    leave_type { :vacation }
    start_date { Date.today + 7 }
    end_date   { Date.today + 9 }
    reason     { "Taking a break" }
    status     { :pending }

    trait :approved do
      status { :approved }
    end

    trait :denied do
      status { :denied }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :sick do
      leave_type { :sick }
    end

    trait :personal do
      leave_type { :personal }
    end
  end
end
