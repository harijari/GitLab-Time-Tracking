# require 'mongo'

# require 'awesome_print'
# require_relative 'mongo_connection'

require 'axlsx'

class XLSXExporter
	def initialize(mongoConnection)
		@mongoConnection = mongoConnection
	end

	# include Mongo

	# def initialize(mongoConnection)
	# 	# MongoDB Database Connect
	# 	@client = MongoClient.new(url, port)

	# 	@db = @client[dbName]

	# 	@collTimeTracking = @db[collName]
	# end

	# def aggregate(input1)
		
	# 	@collTimeTracking.aggregate(input1)

	# end

	def generateXLSX(issuesData, milestoneData, storyPointsData)

		Axlsx::Package.new do |p|
		  p.workbook.add_worksheet(:name => "Issues") do |sheet|
			sheet.add_row issuesData.first.keys
			
			issuesData.each do |hash|
                                row = hash.values
                                row[4] = row[4].to_i / 3600.0
				sheet.add_row row
		  	end

		  end
		  p.workbook.add_worksheet(:name => "Milestones") do |sheet|
			if milestoneData.empty? == false
				sheet.add_row milestoneData.first.keys
				
				milestoneData.each do |hash|
					sheet.add_row hash.values
			  	end

			elsif milestoneData.empty? == true
				sheet.add_row ["No Milestone Data"]
			end
		  end

				  p.workbook.add_worksheet(:name => "Story points") do |sheet|
					  if storyPointsData.empty? == false
						  sheet.add_row storyPointsData.first.keys

						  storyPointsData.each do |hash|
							  sheet.add_row hash.values
						  end
					  else
						  sheet.add_row ["No story points data"]
					  end
				  end

		  return p.to_stream
		end
	end

		def get_all_story_points(downloadID)
				return @mongoConnection.aggregate([
						{ "$match" => { points: { "$ne" => nil} }},
						{"$project" => {_id: 0, 
														download_id: "$admin_info.download_id",
														project: "$project_info.path_with_namespace",
														issue_number: "$iid",
														issue_title: "$title",
														issue_state: "$state",
														issue_points: "$points",
														duration: "$comments.time_tracking_data.duration",
														}},
						{ "$match" => {download_id: downloadID}}
														])
		end

	def get_all_issues_time(downloadID)
		# TODO add filtering and extra security around query
		totalIssueSpentHoursBreakdown = @mongoConnection.aggregate([

			{ "$unwind" => "$comments"},
			{"$project" => {_id: 0,

                                                        project: "$project_info.path_with_namespace",
                                                        issue_id: "$iid",
                                                        date: "$comments.time_tracking_data.work_date",
                                                        person: "$comments.time_tracking_data.work_logged_by",
							time: "$comments.time_tracking_data.duration",
							comment: "$comments.time_tracking_data.time_comment",
							issue_title: "$title",
                                                        this_is_free_time: "$comments.time_tracking_data.non_billable",
                                                        version: { "$ifNull" => [ "$milestone.title", "n/a" ] },
                                                        download_id: "$admin_info.download_id"
                                                        }},
			{ "$match" => {download_id: downloadID}},
                        { "$sort" => { date: 1 }},

			# { "$unwind" => "$comments.time_tracking_data" },


			# { "$match" => { "comments.time_tracking_commits.type" => { "$in" => ["Issue Time"] }}},
			# { "$group" => { _id: {
			# 				project_id: "$project_id",
			# 				id: "$id",
			# 				iid: "$iid",
			# 				title: "$title",
			# 				state: "$state",
			# 				issue_author: "$author.username",
			# 				comment_id: "$comment.id",
			# 				comment_author: "$comment.author.username",
			# 				time_track_duration: "$comment.time_tracking_data.duration",
			# 				time_track_non_billable: "$comment.time_tracking_data.non_billable",
			# 				time_track_work_date: "$comment.time_tracking_data.work_date",
			# 				time_track_time_comment: "$comment.time_tracking_data.time_comment",
			# 				},

			# 				}}
							])
		#output = []
		#totalIssueSpentHoursBreakdown.each do |x|
		#	output << x["_id"]
		#end
		#return output
	end

	def get_all_milestone_budgets(downloadID)
		# TODO add filtering and extra security around query
		totalMileStoneBudgetHoursBreakdown = @mongoConnection.aggregate([

			{ "$match" => { milestone: { "$ne" => nil} }},
			# { "$unwind" => "$comments" },
			{"$project" => {_id: 0,
							download_id: "$admin_info.download_id",
							project_id: 1, 
							id: 1,
							iid: 1,
							type: "$milestone.milestone_budget_data.type",
							milestone_number: "$milestone.iid",
							milestone_title: "$milestone.title",
							milestone_budget_comment: "$milestone.milestone_budget_data.budget_comment",
							milestone_state: "$milestone.state",
							milestone_due_date: "$milestone.due_date",
							milestone_budget_duration: "$milestone.milestone_budget_data.duration",
							}},
			{ "$match" => {download_id: downloadID}},
			{ "$group" => {_id: {
							download_id: "$download_id", 
							type: "$type",
							milestone_number: "$milestone_number",
							project_id: "$project_id", 
							id: "$id",
							iid: "$iid",
							milestone_title: "$milestone_title",
							milestone_budget_comment: "$milestone_budget_comment",
							milestone_state: "$milestone_state",
							milestone_due_date: "$milestone_due_date",
							milestone_budget_duration: "$milestone_budget_duration",
			}}}

			# { "$unwind" => "$comments.time_tracking_data" },


			# { "$match" => { "comments.time_tracking_commits.type" => { "$in" => ["Issue Time"] }}},
			# { "$group" => { _id: {
			# 				project_id: "$project_id",
			# 				id: "$id",
			# 				iid: "$iid",
			# 				title: "$title",
			# 				state: "$state",
			# 				issue_author: "$author.username",
			# 				comment_id: "$comment.id",
			# 				comment_author: "$comment.author.username",
			# 				time_track_duration: "$comment.time_tracking_data.duration",
			# 				time_track_non_billable: "$comment.time_tracking_data.non_billable",
			# 				time_track_work_date: "$comment.time_tracking_data.work_date",
			# 				time_track_time_comment: "$comment.time_tracking_data.time_comment",
			# 				},

			# 				}}
							])
		output = []
		totalMileStoneBudgetHoursBreakdown.each do |x|
			output << x["_id"]
		end
		return output
	end


end


# Testing Code

# m = Mongo_Connection.new("localhost", 27017, "GitLab", "Issues_Time_Tracking") 
# export = XLSXExporter.new(m)


# ap export.get_all_milestone_budgets("ddaed040-7c1a-4829-a07d-1d8608469ef4")
# ap export.get_all_issues_time("ddaed040-7c1a-4829-a07d-1d8608469ef4")

