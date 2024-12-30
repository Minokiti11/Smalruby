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
	grid_centers_in_initial_pos = []
	got_items_pos = [] #取得した後に探索を行っていないアイテムの座標
	routes = nil
	checked_item_exsistence = true
	prev_routes = nil

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

	def k_means_clustering(n, data_points, max_iterations = 100)
		# 初期値としてランダムにn個の中心点を選択
		centroids = data_points.sample(n)
		
		clusters = Array.new(n) { [] }
		
		max_iterations.times do
			# 各データポイントを最も近い中心点に割り当てる
			clusters = Array.new(n) { [] }
			data_points.each do |point|
				distances = centroids.map { |centroid| euclidean_distance(point, centroid) }
				closest_centroid_index = distances.each_with_index.min[1]
				clusters[closest_centroid_index] << point
			end
		
			# 新しい中心点を計算
			new_centroids = clusters.map do |cluster|
				cluster.empty? ? centroids[clusters.index(cluster)] : mean_point(cluster)
			end
		
			break if (new_centroids - centroids).abs < 0.5 # 中心点が変化しなければ終了
		
			centroids = new_centroids
		end
		
		{ clusters: clusters, centroids: centroids }
	end
	
	# 距離を計算(壁を考慮するためダイクストラ法で求める)
	def euclidean_distance(point1, point2)
		if calc_route(src: point1, dst: point2)[1] != nil
			return calc_route(src: point1, dst: point2).length
		else
			return 100
		end
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
		p_arround = [p_east, p_west, p_north, p_south]
		traps = locate_objects(cent: ([8, 8]), sq_size: 15)
		p_around.each do |a|
			if traps.include?(a) || [enemy_x, enemy_y] == a || map(a) == 1 || map(a) == 2
				p_around.delete(a)
			end
		end
		if p_around.empty?
			turn += 1
			turn_over
		else
			routes = [[player_x, player_y], p_around[0]]
		end
	end

	loop do
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

		if all_treasures.include?([player_x, player_y]) && !not_searching_flag && !after_bomb
			got_items_pos.push([player_x, player_y])
			got_items_pos.each do |got_item_pos|
				all_treasures.delete([got_item_pos[0], got_item_pos[1]])
			end
		end

		kowaseru = locate_objects(cent: ([8, 8]), sq_size: 15, objects: ([5]))
		if turn >= 9 && !not_searching_flag && !after_bomb
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

				time1 = Time.now
				# MSE（平均平方誤差）< 4になるまでクラスタ数を増やす
				loop do
					if mse < 2
						break
					end
					mse = 0
					cluster_n += 1
					result = k_means_clustering(cluster_n, all_treasures)
					clusters = result[:clusters]
					centroids = result[:centroids]

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
				end
				time2 = Time.now - time1
				p "Took #{time2} seconds to find the clusters."
			end

			puts "Clusters(n=#{cluster_n}) = #{result[:clusters]}"
			puts "Centroids: #{result[:centroids]}"
			puts "MSE = #{mse}"

			if other_x == (nil) || other_y == (nil)
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
				end
			else
				p "Searching for other player..."
				get_map_area(other_x,other_y)
				if !(other_x == nil)
					other_x = other_player_x
					other_y = other_player_y
					other_footprint.push([other_x, other_y])
				end
			end
		end
		

		if after_bomb
			get_map_area(player_x, player_y)
			after_bomb = false
		end
		kowaseru = locate_objects(cent: ([8, 8]), sq_size: 15, objects: ([5]))
		items_value = {}

		treasures = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["a", "b", "c", "d", "e"]))
		got_items_pos.each do |got_item_pos|
			treasures.delete([got_item_pos[0], got_item_pos[1]])
		end

		# 近い順に並び替える
		treasures.sort_by!{|treasure| calc_route(dst: treasure).size }
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
			if kowaseru_in_routes > num_of_dynamite_you_have
				#ダイナマイトを通らない経路を調べる
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
			other_player_routes_length = other_player_routes
			if other_player_routes[1] == nil
				other_player_routes_length = 100
			else
				other_player_routes_length = other_player_routes.length
			end

			if routes[1] == nil || other_player_routes_length < routes.length
				time1 = Time.now
				while routes[1] == nil || other_player_routes_length < routes.length
					if i + 1 > treasures.length && i != 0
						p "Go to the goal."
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
	
						if routes[1] == nil
							traps_c.each do |c|
								except.delete(c)
							end
							routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except)
	
							if routes[1] == nil
								traps_d.each do |d|
									except.delete(d)
								end
								routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except)
	
								if routes[1] == nil
									#どこにも行けない場合は妨害キャラクタや減点アイテムがない隣のセルに移動
									just_move()
								else
									except.push([goal_x, goal_y])
									break
								end
							else
								except.push([goal_x, goal_y])
								break
							end
	
						else
							except.push([goal_x, goal_y])
							break
						end
	
					else
						p :treasures_i, treasures[i]
						routes = dijkstra_route([player_x, player_y], treasures[i], except)
						p :routes, routes
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

		#35ターン以上でアイテムに行くとゴールできない場合
		
		if turn >= 35 && routes.length - 1 + dijkstra_route([routes[-1][0], routes[-1][1]], [goal_x, goal_y], traps_d).length - 1 > 51 - turn
			p "I'll go to the goal."
			traps.each do |trap|
				except_without_goal.push(trap)
			end
			routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except_without_goal)
			p :routes_to_goal_except_all_traps, routes
			kowaseru_in_routes = routes.select{ |r| kowaseru.include?(r) }.length
			p :kowaseru_in_routes, kowaseru_in_routes
			p :num_of_dynamite_you_have, num_of_dynamite_you_have
			if kowaseru_in_routes > num_of_dynamite_you_have
				p "lack of dynamites."
				kowaseru.each do |k|
					except_without_goal.push(k)
				end
				routes = dijkstra_route([player_x, player_y], [goal_x, goal_y], except_without_goal)
				kowaseru.each do |k|
					except_without_goal.delete(k)
				end
				p :routes_to_goal_except_all_traps_and_breakable_walls, routes
			end
			traps.each do |trap|
				except_without_goal.delete(trap)
			end

			if routes[1] == nil || routes.length > 51 - turn
				p "looking for the routes except B, C, D..."
				traps = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["B", "C", "D"]))
				routes = calc_route(src: [player_x, player_y], dst: [goal_x, goal_y], except_cells: traps)
			end

			if routes[1] == nil || routes.length > 51 - turn
				p "looking for the routes except C, D..."
				traps = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["C", "D"]))
				routes = calc_route(src: [player_x, player_y], dst: [goal_x, goal_y], except_cells: traps)
			end

			if routes[1] == nil || routes.length > 51 - turn
				p "looking for the routes except D..."
				traps = locate_objects(cent: ([8, 8]), sq_size: 15, objects: (["D"]))
				routes = calc_route(src: [player_x, player_y], dst: [goal_x, goal_y], except_cells: traps)
			end

			p :route_to_goal, routes
			if routes[1] == nil
				just_move()
			else
				available_points = 60
				A_in_routes = routes.select{ |r| traps_a.include?(r) }.length
				B_in_routes = routes.select{ |r| traps_b.include?(r) }.length
				C_in_routes = routes.select{ |r| traps_c.include?(r) }.length
				D_in_routes = routes.select{ |r| traps_d.include?(r) }.length
				available_points -= A_in_routes * 10
				available_points -= B_in_routes * 20
				available_points -= C_in_routes * 30
				available_points -= D_in_routes * 40
				p :available_points, available_points

				if available_points < 0
					p "Just move...(I'd want to go to the goal but available_points < 0)"
					just_move()
				end
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
			turn += 1
			turn_over
		end

		move_to(routes[1])

		turn += 1
		turn_over
    end
end
