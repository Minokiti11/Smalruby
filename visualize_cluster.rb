# 初期設定用のコード (your setup code here)
Window.width   = 1200
Window.height  = 870
Window.bgcolor = C_WHITE

Window.loop do
  # 画面描画用のコード (your draw code here)
  img_tohu = Image.new(50, 50, [255, 128, 128, 128])
  img_item = Image.new(50, 50, [255, 200, 0, 0])
  i = 1
  clusters = [[[15, 12], [15, 7], [15, 4], [11, 12], [14, 10], [14, 11], [15, 5]], [[9, 6], [7, 7], [7, 6], [9, 7]], [[5, 12]], [[7, 4], [9, 5], [7, 5], [7, 3], [9, 3], [9, 4]], [[1, 5], [1, 1], [2, 1], [1, 7]]]
  center_points = [[1, 4], [5, 12], [14, 8], [8, 7], [8, 4]]
  
	# MSE（平均平方誤差）を計算
	mse = 0
	clusters.each do |cluster|
		index_of_cluster = clusters.index(cluster)
		center_point = center_points[index_of_cluster]
		p :center_point, center_point
		sum_distance = 0
		cluster.each do |data|
			distance = Math.sqrt((center_point[0] - data[0]).abs**2 + (center_point[1] - data[1]).abs**2)
			sum_distance += distance
		end
		average_distance = sum_distance / cluster.length
				
		mse += average_distance
	end
	mse = mse / clusters.length
	
	font = Font.new(32)

	Window.draw_font(50, 50, "MSE: #{mse.to_s}", font, {:color => C_GREEN})
	
  random = Random.new(128)
  
  15.times do
    j = 1
    15.times do
      Window.draw((50*j) + j, (50*i) + i, img_tohu)
      j += 1
    end
    i += 1
  end
  
  clusters.each do |cluster|
    img_item = Image.new(50, 50, [255, random.rand(255), random.rand(255), random.rand(255)])
    cluster.each do |item|
      Window.draw((50*item[0]) + item[0], (50*item[1]) + item[1], img_item)
    end
  end
end