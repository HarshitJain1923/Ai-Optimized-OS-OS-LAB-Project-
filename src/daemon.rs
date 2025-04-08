// Add these to your imports
use std::collections::HashMap;
use std::fs::File;
use std::io::{Read, Write};
use std::time::{Duration, Instant};

// Add this struct to the file
struct ResourceLearner {
    // Simple Q-learning state-action values
    q_values: HashMap<(String, String), f64>,
    // Track system states
    state_history: Vec<(String, f64)>,
    // Learning parameters
    learning_rate: f64,
    discount_factor: f64,
    exploration_rate: f64,
    last_update: Instant,
}

impl ResourceLearner {
    fn new() -> Self {
        // Try to load saved model
        let mut q_values = HashMap::new();
        if let Ok(mut file) = File::open("/var/lib/system76-power/ml_model.dat") {
            let mut contents = String::new();
            if file.read_to_string(&mut contents).is_ok() {
                for line in contents.lines() {
                    if let Some((key, value)) = line.split_once(':') {
                        if let Some((state, action)) = key.split_once(',') {
                            if let Ok(q_value) = value.parse::<f64>() {
                                q_values.insert((state.to_string(), action.to_string()), q_value);
                            }
                        }
                    }
                }
            }
        }
        
        ResourceLearner {
            q_values,
            state_history: Vec::new(),
            learning_rate: 0.1,
            discount_factor: 0.95,
            exploration_rate: 0.1,
            last_update: Instant::now(),
        }
    }
    
    fn get_system_state(&self) -> String {
        // Get current CPU load
        let mut cpu_load = 0.0;
        if let Ok(mut file) = File::open("/proc/loadavg") {
            let mut contents = String::new();
            if file.read_to_string(&mut contents).is_ok() {
                if let Some(load_str) = contents.split_whitespace().next() {
                    cpu_load = load_str.parse::<f64>().unwrap_or(0.0);
                }
            }
        }
        
        // Categorize load into discrete states
        if cpu_load < 0.5 {
            "low_load".to_string()
        } else if cpu_load < 2.0 {
            "medium_load".to_string()
        } else {
            "high_load".to_string()
        }
    }
    
    fn choose_action(&mut self, state: &str) -> String {
        // Possible actions: balanced, performance, battery
        let actions = vec!["balanced", "performance", "battery"];
        
        // Epsilon-greedy policy
        if rand::random::<f64>() < self.exploration_rate {
            // Random exploration
            actions[rand::random::<usize>() % actions.len()].to_string()
        } else {
            // Greedy exploitation
            let mut best_action = "balanced".to_string();
            let mut best_value = f64::NEG_INFINITY;
            
            for action in actions {
                let key = (state.to_string(), action.to_string());
                let value = *self.q_values.get(&key).unwrap_or(&0.0);
                if value > best_value {
                    best_value = value;
                    best_action = action.to_string();
                }
            }
            
            best_action
        }
    }
    
    fn update(&mut self, reward: f64) {
        if self.state_history.len() < 2 {
            return;
        }
        
        // Get previous and current state-action pair
        let (prev_state, prev_reward) = &self.state_history[self.state_history.len() - 2];
        let (curr_state, _) = &self.state_history[self.state_history.len() - 1];
        
        // Calculate temporal difference
        let prev_q = *self.q_values.get(&(prev_state.clone(), curr_state.clone())).unwrap_or(&0.0);
        let curr_max_q = self.get_max_q_value(curr_state);
        
        // Q-learning update rule
        let new_q = prev_q + self.learning_rate * (prev_reward + self.discount_factor * curr_max_q - prev_q);
        self.q_values.insert((prev_state.clone(), curr_state.clone()), new_q);
        
        // Save model periodically
        if self.last_update.elapsed() > Duration::from_secs(3600) {
            self.save_model();
            self.last_update = Instant::now();
        }
    }
    
    fn get_max_q_value(&self, state: &str) -> f64 {
        let actions = vec!["balanced", "performance", "battery"];
        let mut max_q = f64::NEG_INFINITY;
        
        for action in actions {
            let key = (state.to_string(), action.to_string());
            let q = *self.q_values.get(&key).unwrap_or(&0.0);
            if q > max_q {
                max_q = q;
            }
        }
        
        max_q
    }
    
    fn record_state_action(&mut self, state: String, reward: f64) {
        self.state_history.push((state, reward));
        if self.state_history.len() > 10 {
            self.state_history.remove(0);
        }
    }
    
    fn save_model(&self) {
        if let Ok(mut file) = File::create("/var/lib/system76-power/ml_model.dat") {
            for ((state, action), value) in &self.q_values {
                let line = format!("{},{}:{}\n", state, action, value);
                let _ = file.write(line.as_bytes());
            }
        }
    }
}


pub struct PowerDaemon {
    // existing fields...
    ml_resource_learner: ResourceLearner,
}

impl PowerDaemon {
    pub fn new() -> Result<Self, String> {
        // existing code...
        
        Ok(PowerDaemon {
            // existing fields...
            ml_resource_learner: ResourceLearner::new(),
        })
    }
}



pub fn set_profile(&mut self, profile: Profile) -> Result<(), String> {
    // Get current system state
    let state = self.ml_resource_learner.get_system_state();
    
    // Let ML model choose the action (profile)
    let ml_recommended_profile = self.ml_resource_learner.choose_action(&state);
    let selected_profile = match ml_recommended_profile.as_str() {
        "performance" => Profile::Performance,
        "battery" => Profile::Battery,
        _ => Profile::Balanced,
    };
    
    // Use the ML-recommended profile (or use profile parameter if you prefer)
    // If you want to override with user selection sometimes:
    let final_profile = if rand::random::<f64>() < 0.7 {
        selected_profile
    } else {
        profile
    };
    
    // existing profile switching code...
    
    // Measure system performance
    let performance_score = self.measure_performance();
    self.ml_resource_learner.record_state_action(ml_recommended_profile, performance_score);
    self.ml_resource_learner.update(performance_score);
    
    Ok(())
}

fn measure_performance(&self) -> f64 {
    // Simple performance metric based on CPU load and battery status
    let mut performance = 0.0;
    
    // Check if battery is discharging
    let mut is_discharging = false;
    if let Ok(mut file) = File::open("/sys/class/power_supply/BAT0/status") {
        let mut contents = String::new();
        if file.read_to_string(&mut contents).is_ok() {
            is_discharging = contents.trim() == "Discharging";
        }
    }
    
    // Read CPU load
    let mut cpu_load = 1.0;
    if let Ok(mut file) = File::open("/proc/loadavg") {
        let mut contents = String::new();
        if file.read_to_string(&mut contents).is_ok() {
            if let Some(load_str) = contents.split_whitespace().next() {
                cpu_load = load_str.parse::<f64>().unwrap_or(1.0);
            }
        }
    }
    
    // Reward low CPU load when on battery
    if is_discharging {
        performance = 1.0 / (1.0 + cpu_load);
    } else {
        // Reward responsiveness when plugged in
        performance = if cpu_load < 3.0 { 1.0 } else { 0.5 };
    }
    
    performance
}