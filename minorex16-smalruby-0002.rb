require "smalruby"
require 'set'
require 'matrix'

cat1 = Character.new(costume: "costume1:cat1.png", x: 200, y: 200, angle: 0)
include AI


cat1.on(:start) do
	set_name("minorex16v1.0")
	connect_game
	turn = 1
	start_x = player_x
	start_y = player_y
	other_x = nil
	other_y = nil
	other_footprint = []
	goal = [goal_x, goal_y]
	num_of_dynamite_you_have = 2
	not_searching_flag = false
	after_bomb = false
	set_bomb_flag = false
	grid_centers_in_initial_pos = []
	got_items_pos = [] #取得した後に探索を行っていないアイテムの座標
	routes = nil
	checked_item_exsistence = true
	prev_routes = nil
	current_cluster = nil
	go_to_goal_flag = false
	prev_treasures = nil
	clusters = []
	clusters_value = {}
	EXCEPT = [[goal_x, goal_y],[0,0],[0,1],[0,2],[0,3],[0,4],[0,5],[0,6],[0,7],[0,8],[0,9],[0,10],[0,11],[0,12],[0,13],[0,14],[0,15],[0,16],[1,0],[2,0],[3,0],[4,0],[0,4],[5,0],[6,0],[7,0],[8,0],[9,0],[10,0],[11,0],[12,0],[13,0],[14,0],[15,0],[16,0],[16,1],[16,2],[16,3],[16,4],[16,5],[16,6],[16,7],[16,8],[16,9],[16,10],[16,11],[16,12],[16,13],[16,16],[1,16],[2,16],[3,16],[4,16],[5,16],[6,16],[7,16],[8,16],[9,16],[10,16],[11,16],[12,16],[13,16],[14,16],[15,16]]

	# ダイクストラ法により最短経路を求める
	# 点
	# 各点は"m0_0"のような形式のID文字列をもつ
	class Node
		attr_accessor :id, :edges, :cost, :done, :from
		def initialize(id, edges=[], cost=nil, done=false)
			@id, @edges, @cost, @done = id, edges, cost, done
		end
	end

	# 辺
	# Note: Edgeのインスタンスは必ずNodeに紐付いているため、片方の点ID(nid)しか持っていない
	class Edge
		attr_reader :cost, :nid
		def initialize(cost, nid)
			@cost, @nid = cost, nid
		end
	end

	# グラフ
	class Graph
		# 新しいグラフをつくる
		# data : 点のIDから、辺の一覧へのハッシュ
		#   辺は[cost, nid]という形式
		def initialize(data)
			@nodes =
			data.map do |id, edges|
				edges.map! { |edge| Edge.new(*edge) }
				Node.new(id, edges)
			end
		end

		# 二点間の最短経路をNodeの一覧で返す(終点から始点へという順序なので注意)
		# sid : 始点のID(例："m0_0")
		# gid : 終点のID
		def route(sid, gid)
			dijkstra(sid)
			base = @nodes.find { |node| node.id == gid }
			@res = [base]
			while base = @nodes.find { |node| node.id == base.from }
				@res << base
			end
			@res
		end

		# 二点間の最短経路を座標の配列で返す
		# sid : 始点のID
		# gid : 終点のID
		def get_route(sid, gid)
			route(sid, gid)
			@res.reverse.map { |node|
				node.id =~ /\Am(\d+)_(\d+)\z/
				[$1.to_i, $2.to_i]
			}
		end

		# sidを始点としたときの、nidまでの最小コストを返す
		def cost(nid, sid)
			dijkstra(sid)
			@nodes.find { |node| node.id == nid }.cost
		end

		private

		# ある点からの最短経路を(破壊的に)設定する
		# Nodeのcost(最小コスト)とfrom(直前の点)が更新される
		# sid : 始点のID
		def dijkstra(sid)
			@nodes.each do |node|
				node.cost = node.id == sid ? 0 : nil
				node.done = false
				node.from = nil
			end
			loop do
				done_node = nil
				@nodes.each do |node|
					next if node.done or node.cost.nil?
					done_node = node if done_node.nil? or node.cost < done_node.cost
				end
					break unless done_node
					done_node.done = true
					done_node.edges.each do |edge|
					to = @nodes.find{ |node| node.id == edge.nid }
					cost = done_node.cost + edge.cost
					from = done_node.id
					if to.cost.nil? || cost < to.cost
						to.cost = cost
						to.from = from
					end
				end
			end
		end
	end


	def k_means_clustering(n, data_points, max_iterations = 50)
		# 初期値としてランダムにn個の中心点を選択
		centroids = data_points.sample(n)
		# p "centroids = #{centroids}"
		
		clusters = Array.new(n) { [] }
		
		max_iterations.times do
			time1 = Time.now
			# 各データポイントを最も近い中心点に割り当てる
			clusters = Array.new(n) { [] }
			data_points.each do |point|
				distances = centroids.map { |centroid| euclidean_distance(point, centroid) }
				closest_centroid_index = distances.each_with_index.min[1]
				clusters[closest_centroid_index] << point
			end
			time2 = Time.now - time1
			# p "Took #{time2} seconds to check the centroids."
		
			# 新しい中心点を計算
			new_centroids = clusters.map do |cluster|
				cluster.empty? ? centroids[clusters.index(cluster)] : mean_point(cluster)
			end


			# 新旧の中心点の差が全て0.5以下かチェック
			all_close = true
			centroids.each_with_index do |old_centroid, i|
				new_centroid = new_centroids[i]
				old_centroid.each_with_index do |old_val, j|
					if (new_centroid[j] - old_val).abs > 1
						all_close = false
						break
					end
				end
				# 中心点の移動が大きい場合は次のcentroidの確認をスキップ
				break unless all_close
			end

			break if all_close
		
			centroids = new_centroids
		end
		

		{ clusters: clusters, centroids: centroids }
	end
	
	# 距離を計算
	def euclidean_distance(point1, point2)
		# if dijkstra_route(point1, point2, EXCEPT)[1] != nil
		# 	return dijkstra_route(point1, point2, EXCEPT).length
		# else
		# 	return 100
		# end
		Math.sqrt(point1.zip(point2).map { |x, y| (x - y)**2 }.sum)
	end
	
	# クラスタの平均点を計算
	def mean_point(points)
		dimensions = points.first.size
		sums = Array.new(dimensions, 0)
		points.each do |point|
			point.each_with_index { |value, index| sums[index] += value }
		end
		sums.map { |sum| (sum / points.size.to_f).round }
	end

	def just_move()
		p_east = [player_x + 1, player_y]
		p_west = [player_x - 1, player_y]
		p_north = [player_x, player_y + 1]
		p_south = [player_x, player_y - 1]
		p_around = [p_east, p_west, p_north, p_south]
		traps = locate_objects(cent: ([8, 8]), sq_size: 15)
		p_around.each do |a|
			if EXCEPT.include?(a) || traps.include?(a) || [enemy_x, enemy_y] == a || map(a[0], a[1]) == 1 || map(a[0], a[1]) == 2 || map(a[0], a[1]) == 5
				p_around.delete(a)
			end
		end
		if p_around.empty?
			end_time = Time.now - start_time
			p :end_time, end_time
			turn += 1
			turn_over
		else
			return [[player_x, player_y], p_around[0]]
		end
	end

	loop do
		start_time = Time.now
		# 2点間の移動経路を[[x, y], ...]形式で返す
		#
		# src: [x, y] 始点(省略時はプレイヤーの現在座標)
		# dst: [x, y] 終点(省略時はゴール地点)
		# except_cells: [[x1, y1], ...] 通りたくない場所(省略可)
		def dijkstra_route(start, dst, except)
			src_x, src_y = start[0], start[1]
			dst_x, dst_y = dst[0], dst[1]
			except_cells = except
			data = make_data(map_all.map{|i| i=i.dup}, except_cells)
			g = DijkstraSearch::Graph.new(data)
			sid = "m#{src_x}_#{src_y}"
			gid = "m#{dst_x}_#{dst_y}"
			route = g.get_route(sid, gid)
			return route
		end

		# DijkstraSearchのためのグラフ構造を返す
		def make_data(map,except_cells)
			except_cells.each do |cell|
				ex, ey = cell
				map[ey][ex] = 1
			end
			data = {}
			map.size.times do |y|
				map.first.size.times do |x|
					res = []
					[[x, y - 1], [x, y + 1], [x - 1, y], [x + 1, y]].each do |dx, dy|
						next if dx < 0 || dy < 0
						if map[dy] && map[dy][dx]
							case map[dy][dx]
							# 加点アイテムの扱い（通路）
							when "a".."e"
							res << [1, "m#{dx}_#{dy}"]
							# 減点アイテムの扱い（通路）
							when "A".."D"
							res << [1, "m#{dx}_#{dy}"]
							# 通路
							when 0
							res << [1, "m#{dx}_#{dy}"]
							# 水たまり
							when 4
							res << [2, "m#{dx}_#{dy}"]
							# 壊せる壁
							when 5
								res << [2, "m#{dx}_#{dy}"]
							# 未探査セル（通路扱い）
							when -1
							res << [4, "m#{dx}_#{dy}"]
							# 壁
							when 1, 2
							# 通れないので辺として追加しない
							else
							res << [3, "m#{dx}_#{dy}"]
							end
						end
					end
					data["m#{x}_#{y}"] = res
				end
			end
			return data
		end

		# 相手が向かうアイテムを決定する関数
		def decide_item_based_on_recent_path(other_footprint, items)
			return nil if other_footprint.empty? || items.empty?

			# 直近5ターンの位置を取得
			other_player_pos = other_footprint[-1]
			closest_item = nil
			closest_distance = 10000

			# 各アイテムに対して、直近の位置からの距離を計算
			items.each do |item|
				distance = Math.sqrt((other_player_pos[0] - item[0])**2 + (other_player_pos[1] - item[1])**2)
				if distance < closest_distance
					closest_distance = distance
					closest_item = item
				end
			end
			closest_item
		end

		p :not_searching_flag, not_searching_flag
		p :after_bomb, after_bomb
		
		grid_centers = [[3,3], [3,8], [3,13], [8,3], [8,8], [8,13], [13,3], [13,8], [13,13]]
		player_initial_grid = grid_centers.min_by { |center| (center[0]-player_x)**2 + (center[1]-player_y)**2 }
		grid_centers.sort_by! { |center| (center[0]-player_initial_grid[0])**2 + (center[1]-player_initial_grid[1])**2 }
		
		case turn
		when 1
			grid_centers_in_initial_pos = grid_centers
			get_map_area(*grid_centers_in_initial_pos[0])
			get_map_area(*grid_centers_in_initial_pos[1])
			if !(other_player_x == nil)
				other_x = other_player_x
				other_y = other_player_y
				other_footprint.push([other_x,other_y])
			end
			turn += 1
			turn_over
			next
		when 2
			get_map_area(*grid_centers_in_initial_pos[2])
		when 3
			get_map_area(*grid_centers_in_initial_pos[3])
		when 4
			get_map_area(*grid_centers_in_initial_pos[4])
		when 5
			get_map_area(*grid_centers_in_initial_pos[5])
		when 6
			get_map_area(*grid_centers_in_initial_pos[6])
		when 7
			get_map_area(*grid_centers_in_initial_pos[7])
		when 8
			get_map_area(*grid_centers_in_initial_pos[8])
		end

		if !(other_player_x == nil)
			other_x = other_player_x
			other_y = other_player_y
			other_footprint.push([other_x,other_y])
		end
		
		p :other_footprint, other_footprint

		all_treasures = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["a", "b", "c", "d", "e"]))
		traps = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["A", "B", "C", "D"]))
		water_cell = locate_objects(cent:[8, 8], sq_size: 15, objects: ([4]))

		if all_treasures.include?([player_x, player_y]) && !got_items_pos.include?([player_x, player_y])
			got_items_pos.push([player_x, player_y])
		end

		p :got_items_pos, got_items_pos

		got_items_pos.each do |got_item_pos|
			all_treasures.delete([got_item_pos[0], got_item_pos[1]])
		end

		# if set_bomb_flag
		# 	set_bomb_flag = false
		# end

		# if other_footprint.length > 0 && !not_searching_flag
		# 	decided_item = decide_item_based_on_recent_path(other_footprint, all_treasures)
		# 	p :decided_item, decided_item

		# 	traps_c = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["C"]))
		# 	traps_d = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["D"]))

		# 	original_route = calc_route(src: [other_footprint[-1][0], other_footprint[-1][1]], dst: decided_item, except_cells: traps_c + traps_d)
		# 	p :original_route, original_route
		# 	if original_route[1] != nil
		# 		blocked_cells = []
		# 		original_route.each do |cell|
		# 			if cell == original_route[-1]
		# 				break
		# 			end
		# 			# 塞がれるマスを一時的に通れないようにする
		# 			new_route = calc_route(src: [other_footprint[-1][0], other_footprint[-1][1]], dst: decided_item, except_cells: traps_c + traps_d + [cell])
		# 			p :cell, cell

		# 			p :new_route, new_route

		# 			# 経路がなくなるか、経路の長さが10以上増える場合
		# 			if new_route[1].nil? || (new_route.length + new_route.select{ |r| water_cell.include?(r) }.length - (original_route.length + original_route.select{ |r| water_cell.include?(r) }.length) >= 3)
		# 				blocked_cells << cell
		# 			end
		# 		end
		# 		p :blocked_cells, blocked_cells
		# 		blocked_cells.each do |cell|
		# 			if all_treasures.include?(cell) || traps.include?(cell)
		# 				blocked_cells.delete(cell)
		# 			end
		# 		end
		# 		p :blocked_cells, blocked_cells
		# 	end
		# 	if blocked_cells
		# 		if blocked_cells.length > 0 && blocked_cells.include?([player_x, player_y])
		# 			set_bomb(blocked_cells[blocked_cells.index([player_x, player_y])])
		# 			set_bomb_flag = true
		# 		end
		# 	end
		# end

		kowaseru = locate_objects(cent: ([8, 8]), sq_size: 15, objects: ([5]))
		if turn >= 10 && prev_treasures
			if all_treasures.sort != prev_treasures.sort
				got_items = prev_treasures - all_treasures
				p :got_items, got_items
				clusters_value.each_with_index do |cluster, index|
					p :index, index
					if cluster[1][:cluster].include?(got_items[0])
						if cluster[1][:cluster].length == 1
							puts "#{got_items[0]}のアイテムが取得されました．クラスタを削除します．．"
							clusters.delete(clusters[index])
							clusters_value.delete(index)
						elsif cluster[1][:distance] > 51 - turn
							puts "残りのターン数で到達できない距離にあるクラスタを削除します．．"
							clusters.delete(clusters[index])
							clusters_value.delete(index)
						else
							puts "#{got_items[0]}のアイテムが取得されました．クラスタを更新します．．"
							clusters[index].delete(got_items[0])
							p :clusters_value, clusters_value
							clusters_value[index][:cluster] = clusters[index]
							cluster_value = 0
							clusters[index].each do |cell|
								item = map(cell[0], cell[1])
								case item
								when "a"
									cluster_value += 10
								when "b"
									cluster_value += 20
								when "c"
									cluster_value += 30
								when "d"
									cluster_value += 40
								when "e"
									cluster_value += 60
								end
							end
							clusters_value[index][:value] = cluster_value
							clusters[index].sort_by! { |cell| dijkstra_route([player_x, player_y], cell, EXCEPT).size }
							clusters_value[index][:distance] = dijkstra_route([player_x, player_y], clusters[index][-1], EXCEPT).size
							clusters_value[index][:value_per_distance] = cluster_value / clusters_value[index][:distance]
						end
					end
				end
			end
		end
		if turn >= 9
			puts "Clusters(n=#{clusters.length}) = #{clusters}"
		end
		prev_treasures = all_treasures
		if turn == 9
			time1 = Time.now
			cluster_n = [5, all_treasures.size].min
			if cluster_n > 0
				result = k_means_clustering(cluster_n, all_treasures)
				clusters = result[:clusters]
				centroids = result[:centroids]
				i = 0
				while result[:clusters].include?([])
					if i > 5
						break
					end
					result = k_means_clustering(cluster_n, all_treasures)
					clusters = result[:clusters]
					centroids = result[:centroids]
					i += 1
				end

				mse = 0
				clusters.each do |cluster|
					index_of_cluster = clusters.index(cluster)
					centroid = centroids[index_of_cluster]
					sum_distance = 0
					cluster.each do |data|
						distance = Math.sqrt((centroid[0] - data[0]).abs**2 + (centroid[1] - data[1]).abs**2)
						sum_distance += distance
					end
					average_distance = sum_distance / cluster.length
					
					mse += average_distance
				end
				mse = mse / clusters.length
				final_result = {
					clusters: result[:clusters],
					centroids: result[:centroids],
					mse: mse,
				}
			end


			if cluster_n == 5
				mse = 0
				clusters.each do |cluster|
					index_of_cluster = clusters.index(cluster)
					centroid = centroids[index_of_cluster]
					sum_distance = 0
					cluster.each do |data|
						distance = Math.sqrt((centroid[0] - data[0]).abs**2 + (centroid[1] - data[1]).abs**2)
						sum_distance += distance
					end
					average_distance = sum_distance / cluster.length
					
					mse += average_distance
				end
				mse = mse / clusters.length

				final_result = {}
				# MSE（平均平方誤差）< 1.5になるまでクラスタ数を増やす
				# 各クラスタ数ごとに10回試し、MSEが最小となるクラスタリングを採用
				loop do
					distances_array = []
					clustering_results = {}
					80.times do |i|
						result = k_means_clustering(cluster_n, all_treasures)
						clusters = result[:clusters]
						centroids = result[:centroids]
						j = 0
						while result[:clusters].include?([])
							if j > 5
								break
							end
							result = k_means_clustering(cluster_n, all_treasures)
							clusters = result[:clusters]
							centroids = result[:centroids]
							j += 1
						end

						distances_array = []
						clusters.each do |cluster|
							index_of_cluster = clusters.index(cluster)
							centroid = centroids[index_of_cluster]
							sum_distance = 0
							cluster.each do |data|
								distance = Math.sqrt((centroid[0] - data[0]).abs**2 + (centroid[1] - data[1]).abs**2)
								sum_distance += distance
							end
							average_distance = sum_distance / cluster.length
							distances_array.push(average_distance)
						end
						mse = distances_array.sum / clusters.length

						clustering_results[i] = {
							clusters: clusters,
							centroids: centroids,
							mse: mse,
							max_distance: distances_array.max
						}

						if distances_array.max <= 1.2
							break
						end
					end

					final_result = {}
					min_max_distance = 100
					clustering_results.each do |key, value|
						if value[:max_distance] <= 1.2
							if value[:max_distance] < min_max_distance
								min_max_distance = value[:max_distance]
								final_result = {
									clusters: value[:clusters],
									centroids: value[:centroids],
									mse: value[:mse],
									max_distance: value[:max_distance]
								}
							end
						end
					end
					if final_result.empty?
						cluster_n += 1
					else
						if final_result[:max_distance] <= 1.2
							break
						end
					end
				end
				time2 = Time.now - time1
				p "Took #{time2} seconds to define the clusters."
				puts "Clusters(n=#{cluster_n}) = #{final_result[:clusters]}"
				puts "Centroids: #{final_result[:centroids]}"
				puts "MSE = #{final_result[:mse]}"
			end
		end

		if turn >= 9
			if !not_searching_flag && !after_bomb && !set_bomb_flag
				if other_x == (nil) || other_y == (nil)
					if turn <= 15 && other_footprint.length != 0 && other_footprint[-1] != [nil, nil]
						grid_centers = [[3,3], [3,8], [3,13], [8,3], [8,8], [8,13], [13,3], [13,8], [13,13]]
						other_player_initial_grid = grid_centers.min_by { |center| (center[0]-other_footprint[-1][0])**2 + (center[1]-other_footprint[-1][1])**2 }
						grid_centers.sort_by! { |center| (center[0]-other_player_initial_grid[0])**2 + (center[1]-other_player_initial_grid[1])**2 }

						rand_i = rand(0..2)
						grid_pos = grid_centers[rand_i]
						get_map_area(grid_pos[0], grid_pos[1])
					else
						rand_x = rand(1..3)
						rand_y = rand(1..3)
						if rand_x == 1
							rand_x = 3
						elsif rand_x == 2
							rand_x = 8
						else
							rand_x = 13
						end
						if rand_y == 1
							rand_y = 3
						elsif rand_y == 2
							rand_y = 8
						else
							rand_y = 13
						end
						get_map_area(rand_x, rand_y)
	
						if !(other_player_x == nil)
							other_x = other_player_x
							other_y = other_player_y
							other_footprint.push([other_x, other_y])
						else
							other_x = nil
							other_y = nil
						end
					end

				else
					p "Searching for other player..."
					get_map_area(other_x,other_y)
					if !(other_player_x == nil && other_x == nil)
						other_x = other_player_x
						other_y = other_player_y
						other_footprint.push([other_x, other_y])
					else
						other_x = nil
						other_y = nil
					end
				end
			end
		end
		

		if after_bomb
			get_map_area(player_x, player_y)
			after_bomb = false
		end
		kowaseru = locate_objects(cent: ([8, 8]), sq_size: 15, objects: ([5]))

		if turn == 9
			clusters = final_result[:clusters]
			centroids = final_result[:centroids]
			distance_to_each_cluster = []
			clusters.each_with_index do |cluster, index|
				cluster_value = 0
				cluster.each do |cell|
					item = map(cell[0], cell[1])
					case item
					when "a"
						cluster_value += 10
					when "b"
						cluster_value += 20
					when "c"
						cluster_value += 30
					when "d"
						cluster_value += 40
					when "e"
						cluster_value += 60
					end
				end
				cluster.sort_by! { |cell| dijkstra_route([player_x, player_y], cell, EXCEPT).size }
				clusters_value[index] = {
					cluster: cluster,
					centroid: centroids[index],
					value: cluster_value,
					distance: dijkstra_route([player_x, player_y], cluster[-1], EXCEPT).size,
					value_per_distance: cluster_value / dijkstra_route([player_x, player_y], cluster[-1], EXCEPT).size
				}
			end

			p :clusters_value, clusters_value
		end

		treasures = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["a", "b", "c", "d", "e"]))
		got_items_pos.each do |got_item_pos|
			treasures.delete([got_item_pos[0], got_item_pos[1]])
		end

		# 近い順に並び替える
		treasures.sort_by!{|treasure| dijkstra_route([player_x, player_y], treasure, EXCEPT).size + dijkstra_route([player_x, player_y], treasure, EXCEPT).select{ |r| water_cell.include?(r) }.length }

		p :treasures, treasures

		treasures_a = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["a"]))
		got_items_pos.each do |got_item_pos|
			treasures_a.delete([got_item_pos[0], got_item_pos[1]])
		end
		treasures_b = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["b"]))
		got_items_pos.each do |got_item_pos|
			treasures_b.delete([got_item_pos[0], got_item_pos[1]])
		end
		treasures_c = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["c"]))
		got_items_pos.each do |got_item_pos|
			treasures_c.delete([got_item_pos[0], got_item_pos[1]])
		end
		treasures_d = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["d"]))
		got_items_pos.each do |got_item_pos|
			treasures_d.delete([got_item_pos[0], got_item_pos[1]])
		end
		treasures_e = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["e"]))
		got_items_pos.each do |got_item_pos|
			treasures_e.delete([got_item_pos[0], got_item_pos[1]])
		end


		#通らない座標
		except = [[goal_x, goal_y],[0,0],[0,1],[0,2],[0,3],[0,4],[0,5],[0,6],[0,7],[0,8],[0,9],[0,10],[0,11],[0,12],[0,13],[0,14],[0,15],[0,16],[1,0],[2,0],[3,0],[4,0],[0,4],[5,0],[6,0],[7,0],[8,0],[9,0],[10,0],[11,0],[12,0],[13,0],[14,0],[15,0],[16,0],[16,1],[16,2],[16,3],[16,4],[16,5],[16,6],[16,7],[16,8],[16,9],[16,10],[16,11],[16,12],[16,13],[16,16],[1,16],[2,16],[3,16],[4,16],[5,16],[6,16],[7,16],[8,16],[9,16],[10,16],[11,16],[12,16],[13,16],[14,16],[15,16]]
		except_without_goal = [[0,0],[0,1],[0,2],[0,3],[0,4],[0,5],[0,6],[0,7],[0,8],[0,9],[0,10],[0,11],[0,12],[0,13],[0,14],[0,15],[0,16],[1,0],[2,0],[3,0],[4,0],[0,4],[5,0],[6,0],[7,0],[8,0],[9,0],[10,0],[11,0],[12,0],[13,0],[14,0],[15,0],[16,0],[16,1],[16,2],[16,3],[16,4],[16,5],[16,6],[16,7],[16,8],[16,9],[16,10],[16,11],[16,12],[16,13],[16,16],[1,16],[2,16],[3,16],[4,16],[5,16],[6,16],[7,16],[8,16],[9,16],[10,16],[11,16],[12,16],[13,16],[14,16],[15,16]]
		traps = locate_objects(cent:[8, 8], sq_size: 15)

		traps_a = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["A"]))
		traps_b = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["B"]))
		traps_c = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["C"]))
		traps_d = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["D"]))
		traps_c.each do |c|
			except.push(c)
		end
		traps_d.each do |d|
			except.push(d)
		end

		make_decision_time_start = Time.now

		if turn < 9
			p :treasures_first, treasures[0]
			if treasures[0] != nil
				routes = dijkstra_route([player_x, player_y], treasures[0], except + traps_b + traps_a)
				other_player_routes = dijkstra_route([other_player_x, other_player_y], treasures[0], except + traps_b + traps_a)
				p :routes, routes
				p :other_player_routes, other_player_routes
	
				if routes[1] == nil || (other_x != nil && other_player_routes[1] != nil && other_player_routes.length < routes.length)
					p "Changing the route..."
					routes = dijkstra_route([player_x, player_y], treasures[0], except + traps_b)
					p :routes, routes
					if other_x
						other_player_routes = dijkstra_route([other_player_x, other_player_y], treasures[0], except + traps_b)
						p :other_player_routes , other_player_routes
					else
						p "other_player is missing.."
					end
				end
	
				if routes[1] == nil || (other_x != nil && other_player_routes[1] != nil && other_player_routes.length < routes.length)
					p "Changing the route..."
					routes = dijkstra_route([player_x, player_y], treasures[0], except)
					p :routes, routes
					if other_x
						other_player_routes = dijkstra_route([other_player_x, other_player_y], treasures[0], except)
						p :other_player_routes, dijkstra_route([other_player_x, other_player_y], treasures[0], except)
					else
						p "other_player is missing.."
					end
				end
	
				kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
				p :kowaseru_in_routes, kowaseru_in_routes
	
				#手持ちのダイナマイトで足りない場合
				if kowaseru_in_routes > num_of_dynamite_you_have || (calc_route(dst: treasures[0], except_cells: except + traps_b + traps_a)[1] != nil && routes[1] != nil && (calc_route(dst: treasures[0], except_cells: except + traps_b + traps_a).length - routes.length) <= 1)
					#壊せる壁を通らない経路を調べる
					kowaseru.each do |k|
						except.push(k)
					end
					routes = dijkstra_route([player_x, player_y], treasures[0], except + traps_b + traps_a)
					p :except_kowaseru_routes, routes
				end
			end
	
			i = 0
			p :other_player_pos, [other_player_x, other_player_y]
			if !(other_player_x == nil)
				other_player_routes = calc_route(src: [other_player_x, other_player_y], dst: treasures[i], except_cells: locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["C", "D"])))
				if other_player_routes[1] == nil
					other_player_routes_length = 100
				else
					other_player_routes_length = other_player_routes.length
				end
	
				if routes[1] == nil || other_player_routes_length < routes.length
					time1 = Time.now
					while routes[1] == nil || other_player_routes_length < routes.length
						if i >= 15 || (i + 1 > treasures.length && i != 0)
							p "Go to the goal."
							kowaseru.each do |k|
								except.delete(k)
							end
							routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except_without_goal)
							kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
		
							#手持ちのダイナマイトで足りない場合
							if kowaseru_in_routes > num_of_dynamite_you_have
								#ダイナマイトを通らない経路を調べる
								kowaseru.each do |k|
									except.push(k)
								end
								routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except_without_goal)
							end
		
							if routes[1] == nil
								traps_c.each do |c|
									except.delete(c)
								end
								routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except_without_goal)
		
								if routes[1] == nil
									traps_d.each do |d|
										except.delete(d)
									end
									routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except_without_goal)
		
									if routes[1] == nil
										#どこにも行けない場合は妨害キャラクタや減点アイテムがない隣のセルに移動
										routes = just_move()
									end
								end
							end
							available_points = 60
							trap_A_in_routes = routes.select{ |r| traps_a.include?(r) }.length
							trap_B_in_routes = routes.select{ |r| traps_b.include?(r) }.length
							trap_C_in_routes = routes.select{ |r| traps_c.include?(r) }.length
							trap_D_in_routes = routes.select{ |r| traps_d.include?(r) }.length
							available_points -= trap_A_in_routes * 10
							available_points -= trap_B_in_routes * 20
							available_points -= trap_C_in_routes * 30
							available_points -= trap_D_in_routes * 40
							p :available_points, available_points
			
							if available_points <= 0
								p "Just move...(I'd want to go to the goal but available_points < 0)"
								routes = just_move()
							end
							break
						else
							p :treasures_i, treasures[i]
							routes = dijkstra_route([player_x, player_y], treasures[i], except)
							p :routes, routes
							p :routes_length, routes.length
							other_player_routes = calc_route(src: [other_player_x, other_player_y], dst: treasures[i])
							if other_player_routes[1] == nil
								other_player_routes_length = 100
							else
								other_player_routes_length = other_player_routes.length
							end
							p :other_player_routes_length, other_player_routes_length
							i += 1
						end
						p :i, i
					end
					time2 = Time.now - time1
					p :time2, time2
				end
			else
				while routes[1] == nil
					if treasures[i] == nil || i + 1 > treasures.length
						kowaseru.each do |k|
							except.delete(k)
						end
						except.delete([goal_x, goal_y])
						routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except)
						kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
	
						#手持ちのダイナマイトで足りない場合
						if kowaseru_in_routes > num_of_dynamite_you_have
							#ダイナマイトを通らない経路を調べる
							kowaseru.each do |k|
								except.push(k)
							end
							routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except)
						end
						except.push([goal_x, goal_y])
						break
					else
						p :treasures_i, treasures[i]
						routes = dijkstra_route([player_x, player_y], treasures[i], except)
						i += 1
					end
				end
			end
		else
			if all_treasures.length - clusters.length > 7
				if clusters_value.length != 0
					aim_cluster = nil
					if current_cluster
						aim_cluster = current_cluster
						aim_cluster.each do |cell|
							if got_items_pos.include?(cell)
								aim_cluster.delete(cell)
							end
						end
						p "Set Current Cluster as Aim_Cluster."
					else
						aim_cluster = clusters_value.sort_by{ |_, v| -v[:value_per_distance] }[0][1][:cluster]
						p "Set Max_Value_per_Distance_Cluster as Aim_Cluster."
					end
					p :aim_cluster, aim_cluster
					routes = dijkstra_route([player_x, player_y], aim_cluster.sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT).size }[0], EXCEPT + traps_a + traps_b + traps_c + traps_d)
					p :routes, routes
					
					kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
					p :kowaseru_in_routes, kowaseru_in_routes
					p :num_of_dynamite_you_have, num_of_dynamite_you_have

					#手持ちのダイナマイトで足りない場合
					if kowaseru_in_routes > num_of_dynamite_you_have
						#壊せる壁を通らない経路を調べる
						routes = dijkstra_route([player_x, player_y], aim_cluster.sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT).size }[0], EXCEPT + kowaseru + traps_a + traps_b + traps_c + traps_d)
					end

					if routes[1] == nil
						routes = dijkstra_route([player_x, player_y], aim_cluster.sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT).size }[0], EXCEPT + traps_b + traps_c + traps_d)
						#手持ちのダイナマイトで足りない場合
						kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
						if kowaseru_in_routes > num_of_dynamite_you_have
							#壊せる壁を通らない経路を調べる
							routes = dijkstra_route([player_x, player_y], aim_cluster.sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT).size }[0], EXCEPT + kowaseru + traps_a + traps_b + traps_c + traps_d)
						end
					end

					if routes[1] == nil
						routes = dijkstra_route([player_x, player_y], aim_cluster.sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT).size }[0], EXCEPT + traps_c + traps_d)
						#手持ちのダイナマイトで足りない場合
						kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
						if kowaseru_in_routes > num_of_dynamite_you_have
							#壊せる壁を通らない経路を調べる
							routes = dijkstra_route([player_x, player_y], aim_cluster.sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT).size }[0], EXCEPT + kowaseru + traps_a + traps_b + traps_c + traps_d)
						end
					end
					if routes[1] == nil
						available_points = clusters_value.sort_by { |_, v| -v[:value_per_distance] }[0][1][:value]

						trap_A_in_routes = dijkstra_route([player_x, player_y], aim_cluster.sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT).size }[0], EXCEPT + traps_d).select{ |r| traps_a.include?(r) }.length
						trap_B_in_routes = dijkstra_route([player_x, player_y], aim_cluster.sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT).size }[0], EXCEPT + traps_d).select{ |r| traps_b.include?(r) }.length
						trap_C_in_routes = dijkstra_route([player_x, player_y], aim_cluster.sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT).size }[0], EXCEPT + traps_d).select{ |r| traps_c.include?(r) }.length
						available_points -= trap_A_in_routes * 10
						available_points -= trap_B_in_routes * 20
						available_points -= trap_C_in_routes * 30
						p :available_points, available_points
						if available_points > 0
							routes = dijkstra_route([player_x, player_y], aim_cluster.sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT + traps_d).size }[0], EXCEPT + traps_d)
							#手持ちのダイナマイトで足りない場合
							kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
							if kowaseru_in_routes > num_of_dynamite_you_have
								#壊せる壁を通らない経路を調べる
								routes = dijkstra_route([player_x, player_y], aim_cluster.sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT + traps_c + traps_d).size }[0], EXCEPT + kowaseru + traps_a + traps_b + traps_c + traps_d)
							end
						end
					end

					i = 1
					other_player_routes = dijkstra_route([other_x, other_y], aim_cluster.sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT).size }[0], EXCEPT + traps_c + traps_d)

					p :other_player_routes, other_player_routes
					while !(other_x == nil) && !(other_player_routes[1] == nil) && other_player_routes.length < routes.length || routes[1] == nil
						if i > (clusters.length - 1)
							break
						end
						other_player_routes = dijkstra_route([other_x, other_y], clusters_value.sort_by { |_, v| -v[:value_per_distance] }[i][1][:cluster].sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT + traps_c + traps_d).size }[0], EXCEPT + traps_c + traps_d)
						routes = dijkstra_route([player_x, player_y], clusters_value.sort_by { |_, v| -v[:value_per_distance] }[i][1][:cluster].sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT + traps_c + traps_d).size }[0], EXCEPT + traps_a + traps_b + traps_c + traps_d)
						p :routes, routes
						p :other_player_routes, other_player_routes
						kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length

						#手持ちのダイナマイトで足りない場合
						if kowaseru_in_routes > num_of_dynamite_you_have
							#壊せる壁を通らない経路を調べる
							routes = dijkstra_route([player_x, player_y], clusters_value.sort_by { |_, v| -v[:value_per_distance] }[i][1][:cluster].sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT + traps_c + traps_d).size }[0], EXCEPT + kowaseru + traps_a + traps_b + traps_c + traps_d)
						end
						if routes[1] == nil
							routes = dijkstra_route([player_x, player_y], clusters_value.sort_by { |_, v| -v[:value_per_distance] }[i][1][:cluster].sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT + traps_c + traps_d).size }[0], EXCEPT + traps_b + traps_c + traps_d)
							#手持ちのダイナマイトで足りない場合
							kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
							if kowaseru_in_routes > num_of_dynamite_you_have
								#壊せる壁を通らない経路を調べる
								routes = dijkstra_route([player_x, player_y], clusters_value.sort_by { |_, v| -v[:value_per_distance] }[i][1][:cluster].sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT + traps_c + traps_d).size }[0], EXCEPT + kowaseru + traps_a + traps_b + traps_c + traps_d)
							end
						end
						if routes[1] == nil
							routes = dijkstra_route([player_x, player_y], clusters_value.sort_by { |_, v| -v[:value_per_distance] }[i][1][:cluster].sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT + traps_c + traps_d).size }[0], EXCEPT + traps_c + traps_d)
							#手持ちのダイナマイトで足りない場合
							kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
							if kowaseru_in_routes > num_of_dynamite_you_have
								#壊せる壁を通らない経路を調べる
								routes = dijkstra_route([player_x, player_y], clusters_value.sort_by { |_, v| -v[:value_per_distance] }[i][1][:cluster].sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT + traps_c + traps_d).size }[0], EXCEPT + kowaseru + traps_a + traps_b + traps_c + traps_d)
							end
						end
						if routes[1] == nil
							available_points = clusters_value.sort_by { |_, v| -v[:value_per_distance] }[i][1][:value]
			
							trap_A_in_routes = dijkstra_route([player_x, player_y], clusters_value.sort_by { |_, v| -v[:value_per_distance] }[i][1][:cluster].sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT + traps_c + traps_d).size }[0], EXCEPT + traps_d).select{ |r| traps_a.include?(r) }.length
							trap_B_in_routes = dijkstra_route([player_x, player_y], clusters_value.sort_by { |_, v| -v[:value_per_distance] }[i][1][:cluster].sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT + traps_c + traps_d).size }[0], EXCEPT + traps_d).select{ |r| traps_b.include?(r) }.length
							trap_C_in_routes = dijkstra_route([player_x, player_y], clusters_value.sort_by { |_, v| -v[:value_per_distance] }[i][1][:cluster].sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT + traps_c + traps_d).size }[0], EXCEPT + traps_d).select{ |r| traps_c.include?(r) }.length
							available_points -= trap_A_in_routes * 10
							available_points -= trap_B_in_routes * 20
							available_points -= trap_C_in_routes * 30
							p :available_points, available_points
							if available_points > 0
								routes = dijkstra_route([player_x, player_y], clusters_value.sort_by { |_, v| -v[:value_per_distance] }[i][1][:cluster].sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT + traps_d).size }[0], EXCEPT + traps_d)
								#手持ちのダイナマイトで足りない場合
								kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
								if kowaseru_in_routes > num_of_dynamite_you_have
									#壊せる壁を通らない経路を調べる
									routes = dijkstra_route([player_x, player_y], clusters_value.sort_by { |_, v| -v[:value_per_distance] }[i][1][:cluster].sort_by{ |c| dijkstra_route([player_x, player_y], c, EXCEPT + traps_c + traps_d).size }[0], EXCEPT + kowaseru + traps_a + traps_b + traps_c + traps_d)
								end
							else
								i += 1
								next
							end
						end
						i += 1
					end
				else
					go_to_goal_flag = true
				end
			else
				p :treasures_first, treasures[0]
				if treasures[0] != nil
					routes = dijkstra_route([player_x, player_y], treasures[0], EXCEPT + traps_d + traps_c + traps_b + traps_a)
					other_player_routes = dijkstra_route([other_player_x, other_player_y], treasures[0], EXCEPT + traps_d + traps_c + traps_b + traps_a)
					p :routes, routes
					p :other_player_routes, other_player_routes
		
					if routes[1] == nil || (other_x != nil && other_player_routes[1] != nil && other_player_routes.length < routes.length)
						p "Changing the route..."
						routes = dijkstra_route([player_x, player_y], treasures[0], EXCEPT + traps_d + traps_c + traps_b)
						p :routes, routes
						if other_x
							other_player_routes = dijkstra_route([other_player_x, other_player_y], treasures[0], EXCEPT + traps_d + traps_c + traps_b)
							p :other_player_routes , other_player_routes
						else
							p "other_player is missing.."
						end
					end
		
					if routes[1] == nil || (other_x != nil && other_player_routes[1] != nil && other_player_routes.length < routes.length)
						p "Changing the route..."
						routes = dijkstra_route([player_x, player_y], treasures[0], EXCEPT + traps_d + traps_c)
						p :routes, routes
						if other_x
							other_player_routes = dijkstra_route([other_player_x, other_player_y], treasures[0], EXCEPT + traps_d + traps_c)
							p :other_player_routes, dijkstra_route([other_player_x, other_player_y], treasures[0], EXCEPT + traps_d + traps_c)
						else
							p "other_player is missing.."
						end
					end
		
					kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
					p :kowaseru_in_routes, kowaseru_in_routes
		
					#手持ちのダイナマイトで足りない場合
					if kowaseru_in_routes > num_of_dynamite_you_have || (calc_route(dst: treasures[0], except_cells: traps_d + traps_c + traps_b + traps_a)[1] != nil && routes[1] != nil && (calc_route(dst: treasures[0], except_cells: traps_d + traps_c + traps_b + traps_a).length - routes.length) <= 1)
						#壊せる壁を通らない経路を調べる
						kowaseru.each do |k|
							except.push(k)
						end
						routes = dijkstra_route([player_x, player_y], treasures[0], traps_d + traps_c + traps_b + traps_a)
						p :except_kowaseru_routes, routes
					end
				end
		
				i = 0
				p :other_player_pos, [other_player_x, other_player_y]
				if !(other_player_x == nil)
					other_player_routes = calc_route(src: [other_player_x, other_player_y], dst: treasures[i], except_cells: locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["C", "D"])))
					if other_player_routes[1] == nil
						other_player_routes_length = 100
					else
						other_player_routes_length = other_player_routes.length
					end
		
					if routes[1] == nil || other_player_routes_length < routes.length || routes.length > 51 - turn
						time1 = Time.now
						while routes[1] == nil || other_player_routes_length < routes.length || routes.length > 51 - turn
							if i >= 15 || (i + 1 > treasures.length && i != 0)
								p "Go to the goal."
								kowaseru.each do |k|
									except.delete(k)
								end
								routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except_without_goal + traps_d + traps_c)
								kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
			
								#手持ちのダイナマイトで足りない場合
								if kowaseru_in_routes > num_of_dynamite_you_have
									#ダイナマイトを通らない経路を調べる
									routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except_without_goal + traps_d + traps_c + kowaseru)
								end
			
								if routes[1] == nil
									routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except_without_goal + traps_d)
									kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
			
									#手持ちのダイナマイトで足りない場合
									if kowaseru_in_routes > num_of_dynamite_you_have
										#ダイナマイトを通らない経路を調べる
										routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except_without_goal + traps_d + kowaseru)
									end

									if routes[1] == nil
										routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except_without_goal)
										kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
			
										#手持ちのダイナマイトで足りない場合
										if kowaseru_in_routes > num_of_dynamite_you_have
											#ダイナマイトを通らない経路を調べる
											routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except_without_goal + kowaseru)
										end

										if routes[1] == nil
											#どこにも行けない場合は妨害キャラクタや減点アイテムがない隣のセルに移動
											routes = just_move()
										end
									end
								end
								available_points = 60
								trap_A_in_routes = routes.select{ |r| traps_a.include?(r) }.length
								trap_B_in_routes = routes.select{ |r| traps_b.include?(r) }.length
								trap_C_in_routes = routes.select{ |r| traps_c.include?(r) }.length
								trap_D_in_routes = routes.select{ |r| traps_d.include?(r) }.length
								available_points -= trap_A_in_routes * 10
								available_points -= trap_B_in_routes * 20
								available_points -= trap_C_in_routes * 30
								available_points -= trap_D_in_routes * 40
								p :available_points, available_points
				
								if available_points <= 0
									p "Just move...(I'd want to go to the goal but available_points < 0)"
									routes = just_move()
								end
								break
							else
								p :treasures_i, treasures[i]
								routes = dijkstra_route([player_x, player_y], treasures[i], except)
								p :routes, routes
								p :routes_length, routes.length
								other_player_routes = calc_route(src: [other_player_x, other_player_y], dst: treasures[i])
								if other_player_routes[1] == nil
									other_player_routes_length = 100
								else
									other_player_routes_length = other_player_routes.length
								end
								p :other_player_routes_length, other_player_routes_length
								i += 1
							end
							p :i, i
						end
						time2 = Time.now - time1
						p :time2, time2
					end
				else
					while routes[1] == nil
						if treasures[i] == nil || i + 1 > treasures.length
							kowaseru.each do |k|
								except.delete(k)
							end
							except.delete([goal_x, goal_y])
							routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except)
							kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
		
							#手持ちのダイナマイトで足りない場合
							if kowaseru_in_routes > num_of_dynamite_you_have
								#ダイナマイトを通らない経路を調べる
								kowaseru.each do |k|
									except.push(k)
								end
								routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except)
							end
							except.push([goal_x, goal_y])
							break
						else
							p :treasures_i, treasures[i]
							routes = dijkstra_route([player_x, player_y], treasures[i], except)
							i += 1
						end
					end
				end
			end
			p :routes, routes
		end
		make_decision_time = Time.now - make_decision_time_start

		puts "Make Decision Time: #{make_decision_time}s"



		#35ターン以上でアイテムに行くとゴールできない場合
		route_to_goal = dijkstra_route([routes[-1][0], routes[-1][1]], [goal_x, goal_y], except_without_goal) 
		num_of_water_in_route_to_goal = route_to_goal.select{ |r| water_cell.include?(r) }.length
		if go_to_goal_flag || (turn >= 35 && (route_to_goal.length + num_of_water_in_route_to_goal) <= 51 - turn)
			route_to_goal = dijkstra_route([player_x, player_y], [goal_x, goal_y], except_without_goal + traps)
			p :routes_to_goal_except_all_traps, route_to_goal
			kowaseru_in_routes = route_to_goal.select{ |r| kowaseru.include?(r) }.length
			p :kowaseru_in_routes, kowaseru_in_routes
			p :num_of_dynamite_you_have, num_of_dynamite_you_have
			if kowaseru_in_routes > num_of_dynamite_you_have
				p "lack of dynamites."
				route_to_goal = dijkstra_route([player_x, player_y], [goal_x, goal_y], except_without_goal + kowaseru)
				p :routes_to_goal_except_all_traps_and_breakable_walls, route_to_goal
			end

			if route_to_goal[1] == nil || route_to_goal.length > 51 - turn
				p "looking for the routes except B, C, D..."
				traps = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["B", "C", "D"]))
				route_to_goal = calc_route(src: [player_x, player_y], dst: [goal_x, goal_y], except_cells: traps)
			end

			if route_to_goal[1] == nil || route_to_goal.length > 51 - turn
				p "looking for the routes except C, D..."
				traps = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["C", "D"]))
				route_to_goal = calc_route(src: [player_x, player_y], dst: [goal_x, goal_y], except_cells: traps)
			end

			if route_to_goal[1] == nil || route_to_goal.length > 51 - turn
				p "looking for the routes except D..."
				traps = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["D"]))
				route_to_goal = calc_route(src: [player_x, player_y], dst: [goal_x, goal_y], except_cells: traps)
			end

			p :route_to_goal, route_to_goal
			if route_to_goal[1] == nil
				route_to_goal = just_move()
				available_points = 0
			else
				available_points = 60
				trap_A_in_routes = route_to_goal.select{ |r| traps_a.include?(r) }.length
				trap_B_in_routes = route_to_goal.select{ |r| traps_b.include?(r) }.length
				trap_C_in_routes = route_to_goal.select{ |r| traps_c.include?(r) }.length
				trap_D_in_routes = route_to_goal.select{ |r| traps_d.include?(r) }.length
				available_points -= trap_A_in_routes * 10
				available_points -= trap_B_in_routes * 20
				available_points -= trap_C_in_routes * 30
				available_points -= trap_D_in_routes * 40
				p :available_points, available_points
			end
			cluster_index = nil
			clusters.each_with_index do |cluster, index|
				if cluster.include?(routes[-1])
					cluster_index = index
				end
			end
			if cluster_index
				if clusters_value[cluster_index] != nil
					if clusters_value[cluster_index][:value] < available_points
						route = route_to_goal
					end
				else
					route = route_to_goal
				end
			else
				route = route_to_goal
			end
		end

		p "route decided finally: ", routes
		if prev_routes
			p :prev_routes, prev_routes
			if !(routes.all? { |route| prev_routes.include?(route) })
				p "The route has changed from prev turn."
			end
		end
		p :num_of_dynamite_you_have, num_of_dynamite_you_have
		kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
		p :kowaseru_in_routes, kowaseru_in_routes

		prev_routes = routes
		not_searching_flag = kowaseru.include?(routes[3])

		if kowaseru.include?(routes[2])
			set_dynamite(routes[1])
			num_of_dynamite_you_have -= 1
			after_bomb = true
		end

		if kowaseru.include?(routes[1])
			set_dynamite()
			num_of_dynamite_you_have -= 1
			after_bomb = true
		end

		if turn >= 9 && clusters_value && clusters
			clusters_value.each_with_index do |cluster, index|
				if cluster[1][:cluster].include?(routes[1])
					current_cluster = cluster[1][:cluster]
				end
				if current_cluster
					if cluster[1][:cluster].length == 1 && routes[1] == cluster[1][:cluster][0]
						current_cluster = nil
					end
				end
			end
		end

		move_to(routes[1])

		end_time = Time.now - start_time
		p :end_time, end_time
		turn += 1
		turn_over
    end
end
