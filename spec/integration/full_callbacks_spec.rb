# RSpec.describe "Full callback integration" do
#   let(:user_service_class) do
#     Class.new do
#       include SolidCallback
#
#       attr_reader :log
#       attr_accessor :user_id, :admin_mode
#
#       def initialize(user_id)
#         @user_id = user_id
#         @log = []
#         @admin_mode = false
#       end
#
#       # Define callbacks
#       before_call :authenticate
#       before_call :check_permissions, only: [:update_profile, :delete_account]
#       before_call :audit_access, if: :admin_mode?
#       after_call :log_activity
#       around_call :with_timing
#
#       # Skip callbacks for this method
#       skip_callbacks_for :health_check
#
#       # Methods
#       def get_profile
#         @log << "Getting profile for user #{user_id}"
#         { id: user_id, name: "User #{user_id}" }
#       end
#
#       def update_profile(attributes)
#         @log << "Updating profile with #{attributes.inspect}"
#         { id: user_id, updated: true }
#       end
#
#       def delete_account
#         @log << "Deleting account for user #{user_id}"
#         { success: true }
#       end
#
#       def health_check
#         @log << "Health check"
#         { status: "ok" }
#       end
#
#       private
#
#       def authenticate
#         @log << "Authenticating user #{user_id}"
#       end
#
#       def check_permissions
#         @log << "Checking permissions for user #{user_id}"
#       end
#
#       def log_activity
#         @log << "Logging activity"
#       end
#
#       def audit_access
#         @log << "Auditing access (ADMIN MODE)"
#       end
#
#       def with_timing
#         @log << "Starting timing"
#         start_time = Time.now
#         result = yield
#         end_time = Time.now
#         @log << "Completed in #{(end_time - start_time) * 1000}ms"
#         result
#       end
#
#       def admin_mode?
#         @admin_mode
#       end
#     end
#   end
#
#   it "runs appropriate callbacks for get_profile" do
#     service = user_service_class.new(42)
#     result = service.get_profile
#
#     expect(result).to eq({ id: 42, name: "User 42" })
#     expect(service.log).to include(
#                              "Authenticating user 42",
#                              "Starting timing",
#                              "Getting profile for user 42",
#                              "Logging activity"
#                            )
#     expect(service.log).not_to include("Checking permissions for user 42")
#   end
#
#   it "runs all applicable callbacks for update_profile" do
#     service = user_service_class.new(42)
#     result = service.update_profile({ name: "New Name" })
#
#     expect(result).to eq({ id: 42, updated: true })
#     expect(service.log).to include(
#                              "Authenticating user 42",
#                              "Checking permissions for user 42",
#                              "Starting timing",
#                              "Updating profile with {:name=>\"New Name\"}",
#                              "Logging activity"
#                            )
#   end
#
#   it "respects conditional callbacks" do
#     service = user_service_class.new(42)
#     service.admin_mode = true
#     result = service.get_profile
#
#     expect(result).to eq({ id: 42, name: "User 42" })
#     expect(service.log).to include(
#                              "Authenticating user 42",
#                              "Auditing access (ADMIN MODE)",
#                              "Starting timing",
#                              "Getting profile for user 42",
#                              "Logging activity"
#                            )
#   end
#
#   it "respects skipped methods" do
#     service = user_service_class.new(42)
#     result = service.health_check
#
#     expect(result).to eq({ status: "ok" })
#     expect(service.log).to eq(["Health check"])
#   end
# end