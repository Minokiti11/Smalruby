require "smalruby"

cat1 = Character.new(costume: "costume1:cat1.png", x: 200, y: 200, angle: 0)
include AI

cat1.on(:start) do
  dst = (nil)
  set_name("Edu10kabe")
  connect_game
  after_bomb = 0
  turn = 0
  #周囲の壁の座標、通らない位置で登録用
  kabe = [[0,0],[0,1],[0,2],[0,3],[0,4],[0,5],[0,6],[0,7],[0,8],[0,9],[0,10],[0,11],[0,12],[0,13],[0,14],[0,15],[0,16],[16,0],[16,1],[16,2],[16,3],[16,4],[16,5],[16,6],[16,7],[16,8],[16,9],[16,10],[16,11],[16,12],[16,13],[16,14],[16,15],[16,16],[1,0],[2,0],[3,0],[4,0],[5,0],[6,0],[7,0],[8,0],[9,0],[10,0],[11,0],[12,0],[13,0],[14,0],[15,0],[16,0],[1,16],[2,16],[3,16],[4,16],[5,16],[6,16],[7,16],[8,16],[9,16],[10,16],[11,16],[12,16],[13,16],[14,16],[15,16],[16,16]]

  # キャラクターのスタート位置
  start_x = player_x
  start_y = player_y
  dynamite = 0
  enemy = ([enemy_x,enemy_y])
  gogoal = 0
  #相手の座標をとったものを保存しておいて、そこの最新を相手の座標として使う。
  
  #other_player_pos = ([other_player_x,other_player_y])
  opp = []
  opp_clean = []
  goalX = goal_x
  goalY = goal_y

  turntasu = 0
  bomb = 0
  dst_last = 0

  loop do

    p"raw other_p_x,y"
    p(other_player_x,other_player_y)
    p "Turn"
    p(turn)
    p"aite_iti"
    p(opp_clean)

    
    other_player_pos = ([other_player_x,other_player_y])
    
    opp.push([other_player_x,other_player_y])
    opp_clean = opp.select { |element| element != [nil, nil] }
     
    # ゴールを目指すターンを設定
    if turn >= 43
      gogoal = 1
    end
    
    # 爆弾を使うターンを設定
    if turn >= 100
        gogoal = 2
    end
  
    #爆弾を最終的に使う
    if gogoal == 2
        if bomb < 2
            set_bomb
            bomb += 1
        end

        # ４８ターン以降の移動目標地点
        treasures = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["e"]))
        treasures.sort_by!{|treasure| calc_route(dst: treasure).size }
        dst = (treasures.first)
        trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["B","C","D"]))
        route = calc_route(except_cells: trap)
        if (route[1]) == (nil)
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["C","D"]))
          route = calc_route(except_cells: trap)
        end
        if (route[1]) == (nil)
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["D"]))
          route = calc_route(except_cells: trap)
        end
        if (route[1]) == (nil)
          route = calc_route
        end
        if (route.length) <= 51 - turn
          move_to(route[1])
        else
          enemyTrap = (["A","B","C","D"]) + enemy
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: enemyTrap)
          route = calc_route(dst: dst, except_cells: trap)
          if (route[1]) == (nil)
            enemyTrap = (["B","C","D"]) + enemy
            trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: enemyTrap)
            route = calc_route(dst: dst, except_cells: trap)
          end
          if (route[1]) == (nil)
            enemyTrap = (["C","D"]) + enemy
            trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: enemyTrap)
            route = calc_route(dst: dst, except_cells: trap)
          end
          if (route[1]) == (nil)
            enemyTrap = (["D"]) + enemy
            trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: enemyTrap)
            route = calc_route(dst: dst, except_cells: trap)
          end
          if (route[1]) == (nil)
            enemyTrap = enemy
            trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: enemyTrap)
            route = calc_route(dst: dst, except_cells: trap)
          end
          if (route[1]) == (nil)
            route = calc_route
          end
          move_to(route[1])
        end
        turn = turn + 1
        p "treasures"
        p(treasures)
        p "route"
        p(route)
        p "ターン"
        p(turn)
        p "dst"
        p(dst)
        p "40turnover"
        p"raw other_p_x,y"
        p(other_player_pos)
        p "Turn"
        p(turn)
        turn_over
    end

    if gogoal == 1
      get_map_area(player_x, player_y)
      # ４２ターンの後もダイナマイト使う
      kowaseru = locate_objects(cent: ([8,8]), sq_size: 17, objects: ([5]))
      p_east = ([player_x+1,player_y])
      p_eastTreasure = ([player_x+2,player_y])
      p_eastTreasure2 = ([player_x+3,player_y])
      p_eastTreasure3 = ([player_x+2,player_y+1])
      p_eastTreasure4 = ([player_x+2,player_y-1])

      p_west = ([player_x-1,player_y])
      p_westTreasure = ([player_x-2,player_y])
      p_westTreasure2 = ([player_x-3,player_y])
      p_westTreasure3 = ([player_x-2,player_y+1])
      p_westTreasure4 = ([player_x-2,player_y-1])

      p_north = ([player_x,player_y+1])
      p_northTreasure = ([player_x,player_y+2])
      p_northTreasure2 = ([player_x,player_y+3])
      p_northTreasure3 = ([player_x-1,player_y+2])
      p_northTreasure4 = ([player_x+1,player_y+2])
      
      p_south = ([player_x,player_y-1])
      p_southTreasure = ([player_x,player_y-2])
      p_southTreasure2 = ([player_x,player_y-3])
      p_southTreasure3 = ([player_x-1,player_y-2])
      p_southTreasure4 = ([player_x+1,player_y-2])


      goal = ([goal_x,goal_y])
      treasures = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["a","b","c","d","e",3]))
      if dynamite < 2
        if (kowaseru.include?(p_east)) && ((treasures.include?(p_eastTreasure)) || (treasures.include?(p_eastTreasure2)) || (treasures.include?(p_eastTreasure3)) || (treasures.include?(p_eastTreasure4)))
          set_dynamite
          dynamite = dynamite + 1
          turn = turn + 1
          turn_over
        end
        if (kowaseru.include?(p_west)) && ((treasures.include?(p_westTreasure)) || (treasures.include?(p_westTreasure2)) || (treasures.include?(p_westTreasure3)) || (treasures.include?(p_westTreasure4)))
          set_dynamite
          dynamite = dynamite + 1
          turn = turn + 1
          turn_over
        end
        if (kowaseru.include?(p_north)) && ((treasures.include?(p_northTreasure)) || (treasures.include?(p_northTreasure2)) || (treasures.include?(p_northTreasure3)) || (treasures.include?(p_northTreasure4)))
          set_dynamite
          dynamite = dynamite + 1
          turn = turn + 1
          turn_over
        end
        if (kowaseru.include?(p_south)) && ((treasures.include?(p_southTreasure)) || (treasures.include?(p_southTreasure2)) || (treasures.include?(p_southTreasure3)) || (treasures.include?(p_southTreasure4)))
          set_dynamite
          dynamite = dynamite + 1
          turn = turn + 1
          turn_over
        end
      end
      # ４２ターン以降の移動目標地点
      treasures = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["a","b","c","d","e"]))
      treasures.sort_by!{|treasure| calc_route(dst: treasure).size }
      # 目標地点が行ったり来たりにならないようにしている。
      if (treasures.size) == 0
        dst = ([goal_x,goal_y])
      else
        if dst_last == (treasures.second)
          dst = dst_last
        else
          dst = (treasures.first)
          dst_last = dst
        end
      end


      trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["B","C","D"]))
      route = calc_route(except_cells: trap)
      if (route[1]) == (nil)
        trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["C","D"]))
        route = calc_route(except_cells: trap)
      end
      if (route[1]) == (nil)
        trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["D"]))
        route = calc_route(except_cells: trap)
      end
      if (route[1]) == (nil)
        route = calc_route
      end
      if (route.length) <= 51 - turn
        move_to(route[1])
      else
        enemyTrap = (["A","B","C","D"]) + enemy
        trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: enemyTrap)
        route = calc_route(dst: dst, except_cells: trap)
        if (route[1]) == (nil)
          enemyTrap = (["B","C","D"]) + enemy
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: enemyTrap)
          route = calc_route(dst: dst, except_cells: trap)
        end
        if (route[1]) == (nil)
          enemyTrap = (["C","D"]) + enemy
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: enemyTrap)
          route = calc_route(dst: dst, except_cells: trap)
        end
        if (route[1]) == (nil)
          enemyTrap = (["D"]) + enemy
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: enemyTrap)
          route = calc_route(dst: dst, except_cells: trap)
        end
        if (route[1]) == (nil)
          enemyTrap = enemy
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: enemyTrap)
          route = calc_route(dst: dst, except_cells: trap)
        end
        if (route[1]) == (nil)
          route = calc_route
        end
        move_to(route[1])
      end
      turn = turn + 1
      p "treasures"
      p(treasures)
      p "route"
      p(route)
      p "ターン"
      p(turn)
      p "dst"
      p(dst)
      p "40turnover"
      p"raw other_p_x,y"
      p(other_player_pos)
      p "Turn"
      p(turn)
      turn_over
    end


    # １ターンから４２ターンまで
    if gogoal == 0
      # プレイヤーのスタート位置でマップの検索の仕方を変更,ダイナマイトを使って壁を壊した後の再探索
    
      if after_bomb == 1
        get_map_area(player_x, player_y)
        turntasu = turntasu + 1
        after_bomb = 0
      else
        if turn == 0
          get_map_area(player_x, player_y)
        end
        if turn == 1 + turntasu
          # スタート位置A
          if start_x < 7 && start_y < 8
            get_map_area(3, 3)
          end
          # スタート位置B
          if start_x >= 7 && start_y >= 7
            get_map_area(13, 13)
          end
          # スタート位置C
          if start_x >= 7 && start_y < 7
            get_map_area(13, 3)
          end
          # スタート位置D
          if start_x < 7 && start_y >= 8
            get_map_area(3, 13)
          end
        end
        if turn == 2 + turntasu
          # スタート位置A
          if start_x < 7 && start_y < 8
            get_map_area(3, 8)
          end
          # スタート位置B
          if start_x >= 7 && start_y >= 7
            get_map_area(13, 8)
          end
          # スタート位置C
          if start_x >= 7 && start_y < 7
            get_map_area(13, 8)
          end
          # スタート位置D
          if start_x < 7 && start_y >= 8
            get_map_area(3, 8)
          end
        end
        if turn == 3 + turntasu
          # スタート位置A
          if start_x < 7 && start_y < 8
            get_map_area(8, 3)
          end
          # スタート位置B
          if start_x >= 7 && start_y >= 7
            get_map_area(8, 13)
          end
          # スタート位置C
          if start_x >= 7 && start_y < 7
            get_map_area(8, 3)
          end
          # スタート位置D
          if start_x < 7 && start_y >= 8
            get_map_area(8, 13)
          end
        end
        if turn == 4 + turntasu
          # スタート位置A
          if start_x < 7 && start_y < 8
            get_map_area(8, 8)
          end
          # スタート位置B
          if start_x >= 7 && start_y >= 7
            get_map_area(8,8)
          end
          # スタート位置C
          if start_x >= 7 && start_y < 7
            get_map_area(8, 8)
          end
          # スタート位置D
          if start_x < 7 && start_y >= 8
            get_map_area(8, 8)
          end
        end
        if turn == 5 + turntasu
          # スタート位置A
          if start_x < 7 && start_y < 8
            get_map_area(13, 3)
          end
          # スタート位置B
          if start_x >= 7 && start_y >= 7
            get_map_area(13, 3)
          end
          # スタート位置C
          if start_x >= 7 && start_y < 7
            get_map_area(3, 3)
          end
          # スタート位置D
          if start_x < 7 && start_y >= 8
            get_map_area(3, 3)
          end
        end
        if turn == 6 + turntasu
          # スタート位置A
          if start_x < 7 && start_y < 8
            get_map_area(3, 13)
          end
          # スタート位置B
          if start_x >= 7 && start_y >= 7
            get_map_area(3, 13)
          end
          # スタート位置C
          if start_x >= 7 && start_y < 7
            get_map_area(13, 13)
          end
          # スタート位置D
          if start_x < 7 && start_y >= 8
            get_map_area(13, 13)
          end
        end
        if turn == 7 + turntasu
          # スタート位置A
          if start_x < 7 && start_y < 8
            get_map_area(8, 13)
          end
          # スタート位置B
          if start_x >= 7 && start_y >= 7
            get_map_area(3, 8)
          end
          # スタート位置C
          if start_x >= 7 && start_y < 7
            get_map_area(3, 8)
          end
          # スタート位置D
          if start_x < 7 && start_y >= 8
            get_map_area(8, 3)
          end
        end
        if turn == 8 + turntasu
          # スタート位置A
          if start_x < 7 && start_y < 8
            get_map_area(13, 8)
          end
          # スタート位置B
          if start_x >= 7 && start_y >= 7
            get_map_area(8, 3)
          end
          # スタート位置C
          if start_x >= 7 && start_y < 7
            get_map_area(8, 13)
          end
          # スタート位置D
          if start_x < 7 && start_y >= 8
            get_map_area(13, 8)
          end
        end
        if turn == 9 + turntasu
          # スタート位置A
          if start_x < 7 && start_y < 8
            get_map_area(13, 13)
          end
          # スタート位置B
          if start_x >= 7 && start_y >= 7
            get_map_area(3, 3)
          end
          # スタート位置C
          if start_x >= 7 && start_y < 7
            get_map_area(3, 13)
          end
          # スタート位置D
          if start_x < 7 && start_y >= 8
            get_map_area(13, 3)
          end
        end
      end
      # ダイナマイトを置く壁の奥2個先までアイテム探索
      #斜め位置も探索に加えるのも良いかも
      kowaseru = locate_objects(cent: ([8,8]), sq_size: 17, objects: ([5]))
      p_east = ([player_x+1,player_y])
      p_eastTreasure = ([player_x+2,player_y])
      p_eastTreasure2 = ([player_x+3,player_y])
      p_eastTreasure3 = ([player_x+2,player_y+1])
      p_eastTreasure4 = ([player_x+2,player_y-1])

      p_west = ([player_x-1,player_y])
      p_westTreasure = ([player_x-2,player_y])
      p_westTreasure2 = ([player_x-3,player_y])
      p_westTreasure3 = ([player_x-2,player_y+1])
      p_westTreasure4 = ([player_x-2,player_y-1])

      p_north = ([player_x,player_y+1])
      p_northTreasure = ([player_x,player_y+2])
      p_northTreasure2 = ([player_x,player_y+3])
      p_northTreasure3 = ([player_x-1,player_y+2])
      p_northTreasure4 = ([player_x+1,player_y+2])
      
      p_south = ([player_x,player_y-1])
      p_southTreasure = ([player_x,player_y-2])
      p_southTreasure2 = ([player_x,player_y-3])
      p_southTreasure3 = ([player_x-1,player_y-2])
      p_southTreasure4 = ([player_x+1,player_y-2])


      treasures = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["c","d","e",3]))
      goal = ([goal_x,goal_y])
      if dynamite < 2
        if (kowaseru.include?(p_east)) && ((treasures.include?(p_eastTreasure)) || (treasures.include?(p_eastTreasure2)) || (treasures.include?(p_eastTreasure3)) || (treasures.include?(p_eastTreasure4)))
          set_dynamite
          dynamite = dynamite + 1
          turn = turn + 1
          after_bomb =1
          turn_over
        end
        if (kowaseru.include?(p_west)) && ((treasures.include?(p_westTreasure)) || (treasures.include?(p_westTreasure2)) || (treasures.include?(p_westTreasure3)) || (treasures.include?(p_westTreasure4)))
          set_dynamite
          dynamite = dynamite + 1
          turn = turn + 1
          after_bomb =1
          turn_over
        end
        if (kowaseru.include?(p_north)) && ((treasures.include?(p_northTreasure)) || (treasures.include?(p_northTreasure2)) || (treasures.include?(p_northTreasure3)) || (treasures.include?(p_northTreasure4)))
          set_dynamite
          dynamite = dynamite + 1
          turn = turn + 1
          after_bomb =1
          turn_over
        end
        if (kowaseru.include?(p_south)) && ((treasures.include?(p_southTreasure)) || (treasures.include?(p_southTreasure2))  || (treasures.include?(p_southTreasure3)) || (treasures.include?(p_southTreasure4)))
          set_dynamite
          dynamite = dynamite + 1
          turn = turn + 1
          after_bomb =1
          turn_over
        end
      end
      # 10ターン以降は相手の場所が取れていれば、２ターンに一度、相手の座標で相手を追いかける、取れてない場合は狙っているアイテムの周囲を探索
      # 2ターンに１回は自分の周りを調べる
      #other_px = other_player_x
      #other_py = other_player_y



      if (after_bomb == 0 && turn >= 10 + turntasu) && turn % 2 == 1
        get_map_area(player_x,player_y)
     
      end

      #ここで、２ターンに一度、相手の場所を探索
      if (after_bomb == 0 && turn >= 10 + turntasu) && turn % 2 == 0
        #最後の場所opp[-1]にいない場合、そこをさがしつづけてしまう

        if opp_clean.size != 0
            get_map_area(opp_clean[-1][0], opp_clean[-1][1])
            p"okokokokokokokokookook"
            
        else
            get_map_area(rand(3..13), rand(3..13))
        end
      end
    

      # 爆破した後、ルートを再度調べる
      if after_bomb == 1 && turn >= 10 + turntasu
        get_map_area(player_x, player_y)
        after_bomb = 0
        # ここから上はマップ情報の取得
        # アイテム・トラップ情報取得
        # マップ全域の加点アイテムの場所を取得
        treasures = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["c","d","e"]))
        if (treasures.size) == 0
            treasures = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["b","c","d","e"]))
        end
        if (treasures.size) == 0
          treasures = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["a","b","c","d","e"]))
        end
        goal = ([goal_x,goal_y])
        route = (nil)
        # 加点アイテムを近い順に並び替える
        treasures.sort_by!{|treasure| calc_route(dst: treasure).size }
        # 最新の目標地点を設定
        dst = (treasures.first)
        # 通りたくない場所を取得
        trap = locate_objects(cent: ([8,8]), sq_size: 17)
        route = calc_route(dst: dst, except_cells: trap)
        # アイテムに行くrouteが無い場合、いろんなパターンでルートを探す
        if (route[1]) == (nil)
          enemyTrap = (["B","C","D"]) + enemy
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: enemyTrap)
          route = calc_route(dst: dst, except_cells: trap)
        end
        if (route[1]) == (nil)
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["B","C","D"]))
          route = calc_route(dst: dst, except_cells: trap)
        end
        if (route[1]) == (nil)
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["C","D"]))
          route = calc_route(dst: dst, except_cells: trap)
        end
        if (route[1]) == (nil)
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["D"]))
          route = calc_route(dst: dst, except_cells: trap)
        end
        if (route[1]) == (nil)
          route = calc_route(dst: dst)
        end
        if (route[1]) == (nil)
          route = calc_route
        end
        # 要修正！！単純にゴールをよけるルート検索をすればよい
        # 1番目の宝のルートにゴールガ含まれるとき、ルートを2番目の宝で探索
        if (route.include?(goal))
          dst = (treasures.second)
          trap = locate_objects(cent: ([8,8]), sq_size: 17)
          route = calc_route(dst: dst, except_cells: trap)
          if (route[1]) == (nil)
            enemyTrap = (["B","C","D"]) + enemy
            trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: enemyTrap)
            route = calc_route(dst: dst, except_cells: trap)
          end
          if (route[1]) == (nil)
            trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["B","C","D"]))
            route = calc_route(dst: dst, except_cells: trap)
          end
          if (route[1]) == (nil)
            trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["C","D"]))
            route = calc_route(dst: dst, except_cells: trap)
          end
          if (route[1]) == (nil)
            trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["D"]))
            route = calc_route(dst: dst, except_cells: trap)
          end
          if (route[1]) == (nil)
            route = calc_route(dst: dst)
          end
          if (route[1]) == (nil)
            route = calc_route
          end
          move_to(route[1])
          turn = turn + 1
          p "treasures"
          p(treasures)
          p "route"
          p(route)
          p "dst"
          p(dst)
          p "AfterBomb1"
          p"raw other_p_x,y"
          p(other_player_pos)
          p "Turn"
          p(turn)
          turn_over
        else
          move_to(route[1])
          turn = turn + 1
          p "treasures"
          p(treasures)
          p "route"
          p(route)
          p "dst"
          p(dst)
          p "AfterBomb2"
          p"raw other_p_x,y"
          p(other_player_pos)
          p "Turn"
          p(turn)
          turn_over
        end
      end
      # 通常の移動ルート
      # ここから上はマップ情報の取得
      # アイテム・トラップ情報取得
      # マップ全域の加点アイテムの場所を取得
      treasures = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["c","d","e"]))
      
      if (treasures.size) == 0
        treasures = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["b","c","d","e"]))
      end

      if (treasures.size) == 0
        treasures = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["a","b","c","d","e"]))
      end
      goal = ([goal_x,goal_y])
      route = (nil)
      # 近い順に並び替える
      treasures.sort_by!{|treasure| calc_route(dst: treasure).size }

      # 目標地点が行ったり来たりにならないようにしている。
      if (treasures.size) == 0
        dst = ([goal_x,goal_y])
      else
        if dst_last == (treasures.second)
          dst = dst_last
        else
          dst = (treasures.first)
          dst_last = dst
        end
      end
      p(("dstnew"))
      p(dst)
      # goalがルートに含まれないルート探し
      # 通りたくない場所を取得
      trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["B","C","D"]))
      route = calc_route(dst: dst, except_cells: trap)
      # アイテムに行くrouteが無い場合、いろんなパターンでルートを探す
      if (route[1]) == (nil)
        enemyTrap = (["B","C","D"]) + enemy
        trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: enemyTrap)
        route = calc_route(dst: dst, except_cells: trap)
      end
      if (route[1]) == (nil)
        trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["B","C","D"]))
        route = calc_route(dst: dst, except_cells: trap)
      end
      if (route[1]) == (nil)
        trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["C","D"]))
        route = calc_route(dst: dst, except_cells: trap)
      end
      if (route[1]) == (nil)
        trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["D"]))
        route = calc_route(dst: dst, except_cells: trap)
      end
      if (route[1]) == (nil)
        route = calc_route
      end
      # 1番目の宝のルートにゴールガ含まれるとき、ルートを2番目の宝で探索
      if (route.include?(goal))
        dst = (treasures.second)
        # 目標地点が行ったり来たりにならないようにしている。
        if (treasures.size) == 0
            dst = ([goal_x,goal_y])
        else
            if dst_last == (treasures.second)
            dst = dst_last
            else
            dst = (treasures.first)
            dst_last = dst
            end
        end
        trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["B","C","D"]))
        route = calc_route(dst: dst, except_cells: trap)
        if (route[1]) == (nil)
          enemyTrap = (["B","C","D"]) + enemy
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: enemyTrap)
          route = calc_route(dst: dst, except_cells: trap)
        end
        if (route[1]) == (nil)
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["B","C","D"]))
          route = calc_route(dst: dst, except_cells: trap)
        end
        if (route[1]) == (nil)
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["C","D"]))
          route = calc_route(dst: dst, except_cells: trap)
        end
        if (route[1]) == (nil)
          trap = locate_objects(cent: ([8,8]), sq_size: 17, objects: (["D"]))
          route = calc_route(dst: dst, except_cells: trap)
        end
        if (route[1]) == (nil)
          route = calc_route
        end
        move_to(route[1])
        turn = turn + 1
        p "treasures"
        p(treasures)
        p "route"
        p(route)
        p "dst"
        p(dst)
        p "Normal1"
        p"raw other_p_x,y"
        p(other_player_pos)
        p "Turn"
        p(turn)
        turn_over
      else
        move_to(route[1])
        turn = turn + 1
        p "treasures"
        p(treasures)
        p "route"
        p(route)
        p "dst"
        p(dst)
        p "Normal2"
        p"raw other_p_x,y"
        p(other_player_pos)
        p "Turn"
        p(turn)
        turn_over
      end
    end
  end
end

#爆弾の実装（未実装）
#ルート探索のためのアイテム探索の範囲を変更（未実装）
#


#相手の位置と自分の位置を交互に調べる（実装できた）
#ダイナマイトの使用（実装済み）
#マップ探索のポイントのずれの修正（実装）

#負けMAP ２
