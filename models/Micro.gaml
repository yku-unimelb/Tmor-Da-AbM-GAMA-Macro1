/**
* Name: Micro
* Author: Yimo Jiang
* Description: 
* Tags: Tag1, Tag2, TagN
*/
model Micro


global
{
	file shape_file_buildings <- shape_file('2016_building.shp', 0);
	file shape_file_boundary <- shape_file('2016_boundary.shp', 0);
	file shape_file_surface <- shape_file('2016_surface.shp', 0);
	string type_feature <- 'Type';
	string obj_feature <- 'OBJ';
	//string obj_file_location <- '../includes/obj/' parameter: 'Location for .OBJ files';
	file shape_file_roads <- shape_file('../includes/gis-2016-streets/gis-2016-pathways.shp', 0) parameter: 'Road shapefile';
	string road_type_feature <- 'LAYER' parameter: 'Feature name for road type';
	file color_map_file <- csv_file('../includes/color.csv');

	//int initial_population <- 1500 parameter: 'Initial population';
	int population_growth <- 3 parameter: 'P01:Population growth rate (%)';
	float walk_speed <- 3.0 parameter: 'P02:Walking speed (km/h)';
	float male_min_distance <- 0 parameter: 'P03:Min distance for male';
	float male_max_distance <- 400 parameter: 'P04:Max distance for male';
	float female_min_distance <- 0 parameter: 'P05:Min distance for female';
	float female_max_distance <- 400 parameter: 'P06:Max distance for female';
	float children_min_distance <- 0 parameter: 'P07:Min distance for children';
	float children_max_distance <- 400 parameter: 'P08:Max distance for children';
	int male_per_household <- 1 parameter: 'P09:Number of male per household';
	int female_per_household <- 1 parameter: 'P10:Number of female per household';
	int children_per_household <- 2 parameter: 'P11:Number of children per household';
	int male_to_square <- 50 parameter: 'P12:Probability for male to go to the square';
	int female_to_square <- 50 parameter: 'P13:Probability for female to go to the square';
	int children_to_square <- 30 parameter: 'P14:Probability for children to go to the square';
	point square_point <- { 220, 240 } parameter: 'P15:Square location';
	point primary_school_point <- { 7, 97 } parameter: 'P16:Primary school location';
	point secondary_school_point <- { 295, 140 } parameter: 'P17:Secondary school location';
	float chance_to_wander <- 0 parameter: 'P18:Probability to go to wander location';
	point wander_one <- { 0, 0 } parameter: 'P19:Wander location one';
	point wander_two <- { 0, 0 } parameter: 'P20:Wander location two';
	int days_per_cycle <- 180 parameter: 'P21:Days per cycle';
	float shop_distance_to_road <- 20 parameter: 'P22:Max distance between the road/path and a shop';
	float distance_to_node <- 50 parameter: 'P23:Max distance considered around node';
	int num_red_path <- 15 parameter: 'P24:Number red paths';
	int num_green_path <- 25 parameter: 'P25:Number of green paths';
	int prob_favor <- 50 parameter: 'P26:Probability to build at favored location';
	int start_year <- 2016 parameter: 'P27:Year to start';
	int stop_year <- 2036 parameter: 'P28:Year to stop';
	int grid_size <- 9 parameter: 'P29:Heatmap grid size';
	// set the display boundary to be the envelope of the roads
	geometry shape <- envelope(shape_file_roads);
	// color for differnet buildings
	map<string, rgb> colorMap;

	// store the quantified data for each type of buildings
	map<string, float> count_area;

	// the graph for the roads
	graph road_graph;
	map<paths, float> weights_map;

	// track the population data with growth every cycle
	int total_population;
	int total_capacity;
	bool new_year <- true update: (time / # day) mod 365 <= days_per_cycle and current_date.year > start_year;
	date starting_date <- date([start_year, 1, 1]);
	float step <- days_per_cycle # day;
	list<grids> active_grids;
	
	string result_output <- '../results'; //parameter: 'Folder to save the output';
	matrix results;
	list<string> results_header<- ['x', 'y', 'units'];
	
	init
	{

	// load the color map 
		matrix colorMapFile <- matrix(color_map_file);
		loop i from: 0 to: colorMapFile.rows - 1
		{
			add string(colorMapFile[0, i])::rgb(int(colorMapFile[1, i]), int(colorMapFile[2, i]), int(colorMapFile[3, i])) to: colorMap;
		}

		do load_pathway;
		weights_map <- (agents of_generic_species (road)) as_map (each::each.shape.perimeter);
		road_graph <- as_edge_graph(agents of_generic_species (road)) with_weights weights_map;
		loop v over: road_graph.vertices
		{
			create weighted_nodes with: [location::v];
		}

		// create the initial bulidings from the shapefile
		create unit_factory from: shape_file_buildings with: [type:: string(get(type_feature)), shape_obj::string(get(obj_feature)), height::float(get('Height')), z::float(get('Z'))];

		// create the surface from the shapefile		
		if file_exists('2016_surface.shp')
		{
			create unit_factory from: shape_file_surface with: [type:: string(get(type_feature)), shape_obj::string(get(obj_feature)), height::float(get('Height'))];
		}

		total_population <- length(agents of_generic_species (people));
		active_grids <- grids where (!empty((home+shop) overlapping each));
		// initialize statistics
		do update_stats;

		// initialize results header
		//results <- ['Year','Population','Capacity','Home Area','Shop Area','Temple Area','Church Area'] 
		//	as_matrix({7,40});
		//do update_results;

	}

	reflex update
	{
		list<road> weighted_road <- agents of_generic_species road sort_by (each.passes * -1);
		list<road> red_road <- first(num_red_path, weighted_road);
		weighted_road <- ((agents of_generic_species road) - red_road) sort_by (each.passes * -1);
		list<road> green_road <- first(num_green_path, weighted_road);
		ask red_road
		{
			self.color <- # red;
		}

		ask green_road
		{
			self.color <- # green;
		}

		ask (agents of_generic_species road) - red_road - green_road
		{
			if self.passes > 0
			{
				self.color <- # blue;
			}

		}

	}

	// population increase every year 
	reflex new_year when: new_year
	{
		if current_date.year = stop_year
		{
			// save the results
			int results_columns <- 3;
			int results_rows <- count(home+shop,each.location.z = 0)+2;
			results <- results_header as_matrix ({ results_columns, results_rows });
			results[0, results_rows - 1] <- 'Wander 1: ' + wander_one + ' Wander 2: '+wander_two;
		
			string machine_time_string <- string(int(floor(machine_time / 1000000))) + string(int(machine_time - floor(machine_time / 1000000) * 1000000));
			string output_name <- result_output + "/" + machine_time_string;
			
			ask (home+shop) where (each.location.z = 0) {
				loop i from:0 to:results.rows-1 {
					if results[2,i] = nil {
					results[0,i] <- self.location.x;
					results[1,i] <- self.location.y;
					results[2,i] <- count(home, each.location.x = self.location.x and each.location.y = self.location.y);
					break;		
					}
				} 
				 
			}

			save results to: output_name + '.csv' type: "csv";
			do pause;
		}

		int new_people <- round(total_population * (population_growth / 100));
		total_population <- round(total_population * (1 + population_growth / 100));

		// nothing will be built at the beginning of the simulation
		if current_date.year > start_year
		{
			do build_up(new_people);
		}

		do update_stats;
		// save output data every year
		//do update_results;

	}

	action load_pathway
	{
	// create paths from the shapefile
		loop path_shape over: shape_file_roads
		{
			string path_type <- path_shape get road_type_feature;
			int destroy <- int(path_shape get 'DESTROY');
			if destroy = 0
			{
				create unit_factory with: [shape::path_shape, type:: path_type];
			}

		}

	}

	action build_up (int n)
	{
		list<weighted_nodes> sorted_nodes <- weighted_nodes sort_by (each.weight * -1);
		list<weighted_nodes> top_weight <- first_of(3, sorted_nodes);
		write top_weight;

		// build the new buildings
		int new_units <- round(n / (male_per_household + female_per_household + children_per_household));
		loop i from: 0 to: new_units - 1
		{
			building base;
			// build somewhere next to the road
			if rnd(100) < prob_favor
			{
				base <- one_of(shop where (each.location.z = 0 and (roads closest_to each) distance_to each <= shop_distance_to_road ));
				if base != nil
				{
					do build_on_top(base);
				}

			} else
			{
				weighted_nodes base_node;
				if rnd(100) < prob_favor
				{
					base_node <- top_weight at 0;
				} else
				{
					if rnd(100) < prob_favor
					{
						base_node <- top_weight at 1;
					} else
					{
						base_node <- top_weight at 2;
					}

				}
				//write base_node;
				base <- one_of((home+shop) where (each distance_to base_node < distance_to_node and each.location.z = 0));
			}

			if base != nil
			{
				do build_on_top(base);
			}

		}

	}

	action build_on_top (building base)
	{
		list<building> same_building <- (home + shop) where (each.location.x = base.location.x and each.location.y = base.location.y);
		float new_z <- same_building max_of each.location.z + base.height;
		create unit_factory with: [type:: string(home), location::{ base.location.x, base.location.y, new_z }, shape::rectangle({ base.shape.width, base.shape.height
		}), height::base.height];
	}

	action update_stats
	{
		int total_homes <- length(home);
		int total_grids <- length(active_grids);
		if total_grids > 0
		{

			int level_one <- (total_homes / total_grids)/2 >= 1 ? int((total_homes / total_grids)/2) : 1;
			int level_two <- (total_homes / total_grids) >= 2 ? int(total_homes / total_grids) : 2;
			int level_three <- level_two * 2;
			ask active_grids parallel: true
			{
				list<building> ground_units <- ((home+shop) where (each.location.z = 0)) overlapping self;
				int local_homes;
				if !empty(ground_units)
				{
					loop h over: ground_units
					{
						local_homes <- local_homes + count(home, each.location.x = h.location.x and each.location.y = h.location.y);
					}

				}

				if local_homes <= level_one
				{
					self.color <- # black;
				} else if local_homes <= level_two
				{
					self.color <- # blue;
				} else if local_homes <= level_three
				{
					self.color <- # green;
				} else
				{
					self.color <- # red;
				}

			}

		}
		else {
			active_grids <- grids where (!empty((home+shop) overlapping each));
			write active_grids;
		}

		// count the total capacity of homes
		int current_capacity;
		loop h over: home
		{
			ask h
			{
				current_capacity <- current_capacity + self.capacity;
			}

		}

		total_capacity <- current_capacity;
	}

	// TODO:
	action update_results
	{
	}

}

// heatmap only
grid grids cell_width: grid_size cell_height: grid_size neighbors: 4 schedules: []
{
	init {
		color <- #white;
	}
}

species weighted_nodes schedules: []
{
	float weight;
}

species people skills: [moving]
{
	home living_place;
	float home_height;
	float max_distance;
	//building target_building;
	point the_target;
	string objective;
	path path_followed;
	float speed <- walk_speed # km / # h;
	rgb color;
	bool moving;
	init
	{
		objective <- 'rest';
		home_height <- living_place.location.z + living_place.height;
	}

	action move
	{
		loop while: the_target != nil
		{
			path_followed <- self goto [target::the_target, on::road_graph, return_path::true];
			if empty(path_followed.edges)
			{
			// agent is stuck somehow, kill it
				do die;
			}

			if the_target = location
			{
			//write current_path;
			//write list<road>(current_path.edges);
				ask list<road> (current_path.edges) parallel: true
				{
				//write self;
					passes <- passes + days_per_cycle * count(home, each.location.x = myself.living_place.location.x and each.location.y = myself.living_place.location.y);
					//do register(myself);
				}

				loop p over: current_path.vertices
				{
					ask weighted_nodes where (each.location = p)
					{
						weight <- weight + days_per_cycle;
					}
					//node_weight[location] <- node_weight[location] + days_per_cycle;
				}

				the_target <- nil;
			}

		}

	}

	action go_home
	{
		objective <- 'rest';
		the_target <- any_location_in(living_place) + { 0, 0, home_height };
	}

	aspect default
	{
		draw circle(0.5) color: color;
	}

}

species male parent: people schedules: male where (rnd(100) < male_to_square and rnd(male_min_distance, male_max_distance) >= square_point distance_to each.living_place)
{
	rgb color <- # blue;
	init
	{

	// can't do anything anyway, die straightaway
		if square_point distance_to living_place > male_max_distance
		{
			do die;
		}

	}

	reflex move_around
	{

	// wander to one of the points  before going to square 
		if flip(chance_to_wander / 100) and wander_one != nil
		{
			objective <- 'wander one';
			the_target <- wander_one;
			do move;
		} else if flip(chance_to_wander / 100) and wander_two != nil
		{
			objective <- 'wander two';
			the_target <- wander_two;
			do move;
		}

		objective <- 'square';
		the_target <- square_point;
		do move;
		do go_home;
		do move;
	}

}

species female parent: people schedules: female where (rnd(100) < female_to_square and rnd(female_min_distance, female_max_distance) >= square_point distance_to each.living_place)
{
	rgb color <- # red;
	init
	{
	// can't do anything anyway, die straightaway
		if square_point distance_to living_place > female_max_distance
		{
			do die;
		}

	}

	reflex move_around
	{

	// wander to one of the points  before going to square 
		if flip(chance_to_wander / 100) and wander_one != nil
		{
			objective <- 'wander one';
			the_target <- wander_one;
			do move;
		} else if flip(chance_to_wander / 100) and wander_two != nil
		{
			objective <- 'wander two';
			the_target <- wander_two;
			do move;
		}

		objective <- 'square';
		the_target <- square_point;
		do move;
		do go_home;
		do move;
	}

}

species children parent: people
{
	rgb color <- # white;
	bool square_ok;
	bool primary_ok;
	bool secondary_ok;
	string school_type;
	init
	{
		square_ok <- square_point distance_to living_place < children_max_distance;
		primary_ok <- primary_school_point distance_to living_place < children_max_distance;
		secondary_ok <- secondary_school_point distance_to living_place < children_max_distance;

		// can't do anything anyway, die straightaway
		if !(primary_ok or secondary_ok)
		{
			do die;
		}
		// TODO: I made this up, but I think they'll go to one school and stick with that in 24 hrs
else
		{
			if secondary_ok and primary_ok
			{
				int random <- rnd(100);
				if random < 50
				{
					school_type <- 'primary';
				} else
				{
					school_type <- 'secondary';
				}

			} else if !secondary_ok
			{
				school_type <- 'primary';
			} else
			{
				school_type <- 'secondary';
			}

		}

	}

	reflex move_around
	{

	// wander to one of the points  before going to square 
		if flip(chance_to_wander / 100) and wander_one != nil
		{
			objective <- 'wander one';
			the_target <- wander_one;
			do move;
		} else if flip(chance_to_wander / 100) and wander_two != nil
		{
			objective <- 'wander two';
			the_target <- wander_two;
			do move;
		}

		if rnd(100) < children_to_square and rnd(children_min_distance, children_max_distance) >= square_point distance_to living_place
		{
			objective <- 'square';
			the_target <- square_point;
			do move;
			do go_to_school;
		} else
		{
			do go_to_school;
		}

		do move;
		do go_home;
		do move;
	}

	action go_to_school
	{
		objective <- 'school';
		if school_type = 'primary'
		{
			the_target <- primary_school_point;
		} else
		{
			the_target <- secondary_school_point;
		}

	}

}

// agent factory
species unit_factory schedules: []
{
	string type;
	string shape_obj;
	float height;
	float z;
	init
	{
	//write "creating "+type;
	// translate type to species
		if type contains 'green'
		{
			create greens with: [temp::true] returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'wat'
		{
			create wat with: [temp::true] returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'temple'
		{
			create temple with: [temp::true] returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'orphanage'
		{
			create orphanage with: [temp::true] returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'institute'
		{
			create institute with: [temp::true] returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'church'
		{
			create church with: [temp::true] returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'cemetary'
		{
			create cemetary with: [temp::true] returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'home'
		{
			create home with: [temp::true] returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'school'
		{
			create school with: [temp::true] returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'shop'
		{
			create shop with: [temp::true] returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'void'
		{
			create void with: [temp::true] returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'path'
		{
			create paths with: [temp::true] returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'road'
		{
			create roads with: [temp::true] returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'boundary'
		{
			create boundary with: [temp::true] returns: new_unit;
			do create_new(new_unit at 0);
		}

	}

	action create_new (unit new)
	{
		create species_of(new) with: [location::self.location + { 0, 0, z }, shape::self.shape, shape_obj::self.shape_obj, height::self.height];
		//write type + " created";
		ask new
		{
			do die;
		}

		do die;
	}

}

species unit schedules: []
{
	string type;
	string shape_obj;
	rgb color;
	float height;
	bool temp;
	init
	{
		type <- string(species(self));
		color <- colorMap[type];
	}

	// change to another type of unit	
	action turn_into (unit source, string target)
	{
		create unit_factory with: [location::source.location, type:: target, shape::source.shape, shape_obj::source.shape_obj, height::source.height];
		do die;
	}

}

// polygon of mainroad
species boundary parent: unit schedules: []
{
}

species building parent: unit schedules: []
{
	pair<float, point> rotate_degree;
	bool can_build_on_top;
	int capacity;
	aspect default
	{
		draw shape color: color border: color depth: height;
	}

}

species surface parent: unit schedules: []
{
	init
	{
		height <- 0.0;
	}

	aspect default
	{
		draw shape color: color border: color depth: height;
	}

}

species road parent: unit schedules: []
{
	int passes;
	list<people> distinct_people;
	float weighted_passes;
	init
	{
		color <- # black;
	}

	action register (people p)
	{
		if !(distinct_people contains p)
		{
			add p to: distinct_people;
		}

	}

	aspect default
	{
		draw shape color: color width: 3;
	}

}

species occupiable parent: building schedules: []
{
	list<geometry> base_units;
	float available_area;
	init
	{
	}

	species occupiable_base parent: base_unit
	{
	}

}

species church parent: occupiable schedules: []
{
}

species temple parent: occupiable schedules: []
{
}

species base_unit parent: home schedules: []
{
}

// footprints for possible building locations and shapes
species void parent: building
{
}

species home parent: building schedules: []
{
	int population;
	bool surrounding_populated;
	bool shop_potential;
	init
	{
	// simulate only the ground floor for performance
		if !temp and location.z = 0
		{
		// 50 percent chance to have male or a female
			if flip(0.5)
			{
				if flip(0.5)
				{
					create male number: male_per_household with: [living_place::self, location::any_location_in(self) + { 0, 0, self.location.z + self.height }];
				} else
				{
					create female number: female_per_household with: [living_place::self, location::any_location_in(self) + { 0, 0, self.location.z + self.height }];
				}

			}
			// 50 percent chance to have a family
else
			{
				create male number: male_per_household with: [living_place::self, location::any_location_in(self) + { 0, 0, self.location.z + self.height }];
				create female number: female_per_household with: [living_place::self, location::any_location_in(self) + { 0, 0, self.location.z + self.height }];
				create children number: children_per_household with: [living_place::self, location::any_location_in(self) + { 0, 0, self.location.z + self.height }];
			}

		}

	}

}

species institute parent: building schedules: []
{
}

species orphanage parent: building schedules: []
{
}

species shop parent: building schedules: []
{
	init
	{
		can_build_on_top <- true;
	}

}

species school parent: building schedules: []
{
}

species cemetary parent: surface schedules: []
{
}

species roads parent: road schedules: []
{
}

species paths parent: road schedules: []
{
}

species greens parent: surface schedules: []
{
}

species wat parent: building schedules: []
{
}

experiment main type: gui
{
	output
	{
		display map type: opengl
		{
			species greens;
			species church transparency: 0.5;
			species temple transparency: 0.5;
			species institute;
			species orphanage transparency: 0.5;
			species wat transparency: 0.5;
			species cemetary;
			species school;
			species home;
			species shop;
			species roads;
			species paths;
			species male;
			species female;
			species children;
			graphics 'display_date'
			{
				draw string(current_date) at: { 10, 10 } color: # black;
			}

		}

		display roads
		{
			species roads;
			species paths;
		}

		display heatmap
		{
			grid grids;
		}

	}

}


