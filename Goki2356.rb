require "smalruby"

cat1 = Character.new(costume: "costume1:cat1.png", x: 200, y: 200, angle: 0)
dst = (nil)
include AI

cat1.on(:start) do
  set_name("Goki2356")
  connect_game
  #生徒変更用の変数
  target = ["a", "b", "c", "d", "e"]
  goal_length = 5
  search_enemy_or_me = 0

  loop do
    # 未探索のエリア（マップ情報が「-1」のマス）があるかどうかを確認する
    searched = !(map_all.flatten.include?(-1))
    2.times do
      # 未探索のエリアがある場合は、探索を優先する
      if searched == false
        map_x = -3
        map_y = -3
        # 探索の中心点となるマスのみをチェックし、未探索かどうかを判断する
        4.times do
          map_y = map_y + 5
          if map_y == 17
            map_y = 16
          end
          map_x = -3
          4.times do
            map_x = map_x + 5
            if map_x == 17
              map_x = 16
            end
            if map(map_x,map_y) == -1
              break
            end
          end
          if map(map_x,map_y) == -1
            break
          end
        end
        get_map_area(map_x, map_y)
        searched = !(map_all.flatten.include?(-1))
      end
    end
    # 探索が終わっていなければここでターン終了。turn_over 以外は何もしない
    if searched == true
        if !(dst == (nil))
          get_map_area(player_x, player_y)
        end
      
      # ゴールが近い場合はゴールに向かう
      if (calc_route).length < goal_length
        dst = (nil)
      else
        # マップ全域の加点アイテムの場所を取得
        treasures = locate_objects(cent: ([8, 8]), sq_size: 17, objects: (target))
        # 近い順に並び替える
        treasures.sort_by!{|treasure| calc_route(dst: treasure).size }
        if dst == (nil)
          # 加点アイテムが存在する場合、最も近い加点アイテムに向かう
          # 加点アイテムが存在しない場合(treasures.first が nilの場合)はゴールに向かう
          dst = (treasures.first)
        else
          # 加点アイテムが相手に取られてすでに存在しないか、あるいは、自分が取得した場合、
          # 移動先を最も近い加点アイテムに変更する。
          if !(treasures.include?(dst)) || ([player_x, player_y]) == dst
            dst = (treasures.first)
          end
        end
      end
      #dst が目的地点なので、そこに行くまでに避けたいアイテムがある時には、別のルートを見つける
      trap = locate_objects(cent: ([7, 7]), sq_size: 15)
      route = calc_route(dst: dst, except_cells: trap)
      # アイテムに行くrouteが無い場合、いろんなパターンでルートを探す
      if (route[1]) == (nil)
        trap = locate_objects(cent: ([7, 7]), sq_size: 15, objects: (["B","C","D"]))
        route = calc_route(dst: dst, except_cells: trap)
      end
      if (route[1]) == (nil)
        trap = locate_objects(cent: ([7, 7]), sq_size: 15, objects: (["C","D"]))
        route = calc_route(dst: dst, except_cells: trap)
      end
      if (route[1]) == (nil)
        trap = locate_objects(cent: ([7, 7]), sq_size: 15, objects: (["D"]))
        route = calc_route(dst: dst, except_cells: trap)
      end
      if (route[1]) == (nil)
        route = calc_route(dst: dst)
      end
      if (route[1]) == (nil)
        route = calc_route
      end




      #最終的に決まったルートをもとに移動する
     
      move_to(route[1])
    end
    turn_over
  end
end
