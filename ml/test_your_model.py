"""
Test Your Trained Model - Fixed Version
Tests detectoai_cls_best.pt on your dataset
Automatically finds images in your dataset folders
"""

from ultralytics import YOLO
from PIL import Image
import os
import random

def test_your_model():
    """Test the trained model in results/detectoai_cls_best.pt"""
    
    print("=" * 70)
    print("🧪 TESTING YOUR PHONE DAMAGE DETECTION MODEL")
    print("=" * 70)
    
    model_path = 'results/detectoai_cls_best.pt'
    
    # Check if model exists
    if not os.path.exists(model_path):
        print(f"\n❌ Model not found at: {model_path}")
        print("   Make sure you're running this from the ml/ directory")
        return
    
    print(f"\n📦 Loading model: {model_path}")
    
    try:
        model = YOLO(model_path)
        print("✅ Model loaded successfully!")
    except Exception as e:
        print(f"❌ Error loading model: {e}")
        return
    # Try different possible locations (your files are in the dataset folder)
    base_dir = os.path.dirname(os.path.abspath(__file__))
    possible_paths = [
        os.path.join(base_dir, 'dataset'),         # ml/dataset
        os.path.join(base_dir, '..', 'dataset'),   # parent/dataset
        os.path.join(os.getcwd(), 'dataset'),      # cwd/dataset
        'dataset',                                 # relative
        '.',                                       # folders directly in ml/
    ]
    # Deduplicate while preserving order
    seen = set()
    possible_paths = [p for p in possible_paths if p not in seen and not seen.add(p)]
    
    test_path = None
    for path in possible_paths:
        if os.path.exists(os.path.join(path, 'crack')):
            test_path = path
            break
    
    if test_path is None:
        print("\n❌ Cannot find dataset folders!")
        print("   Looking for: crack/, dent/, pristine/, scratch/")
        print("   Current directory contents:")
        for item in os.listdir('.'):
            print(f"     - {item}")
        return
    
    print(f"\n🖼️  Found dataset at: {test_path}")
    print(f"   Testing on images...\n")
    
    # Categories
    categories = ['crack', 'dent', 'pristine', 'scratch']
    
    # Collect test images - take random samples from each category
    test_images = []
    for category in categories:
        cat_path = os.path.join(test_path, category)
        if os.path.exists(cat_path):
            images = [os.path.join(cat_path, f) for f in os.listdir(cat_path) 
                     if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
            
            # Take 10 random images from each category (or all if less than 10)
            n_samples = min(10, len(images))
            if n_samples > 0:
                random.seed(42)  # For reproducibility
                samples = random.sample(images, n_samples)
                test_images.extend(samples)
                print(f"   📁 {category:10s}: Found {len(images)} images, testing {n_samples}")
    
    if not test_images:
        print("\n❌ No test images found!")
        return
    
    print(f"\n🔬 Testing on {len(test_images)} images total...\n")
    print("-" * 70)
    
    # Track results
    correct = 0
    total = 0
    confusion = {cat: {cat2: 0 for cat2 in categories} for cat in categories}
    
    for img_path in test_images:
        # Get ground truth from folder name
        ground_truth = os.path.basename(os.path.dirname(img_path))
        
        # Skip if not a valid category
        if ground_truth not in categories:
            continue
        
        # Predict
        try:
            results = model(img_path, verbose=False)
            
            # Get prediction
            pred_class = results[0].names[results[0].probs.top1]
            confidence = results[0].probs.top1conf.item()
            
            # Update confusion matrix
            confusion[ground_truth][pred_class] += 1
            
            # Check if correct
            is_correct = pred_class == ground_truth
            if is_correct:
                correct += 1
            total += 1
            
            # Display result
            status = "✅" if is_correct else "❌"
            img_name = os.path.basename(img_path)
            
            print(f"{status} {img_name:30s}")
            print(f"   True: {ground_truth:10s} | Predicted: {pred_class:10s} ({confidence:.1%})")
            
            # Show top 3 predictions
            top3_indices = results[0].probs.top5[:3]
            print(f"   Top 3: ", end="")
            for idx in top3_indices:
                class_name = results[0].names[idx]
                conf = results[0].probs.data[idx].item()
                print(f"{class_name}({conf:.0%}) ", end="")
            print("\n")
            
        except Exception as e:
            print(f"⚠️  Error processing {img_path}: {e}\n")
            continue
    
    # Calculate metrics
    if total == 0:
        print("❌ No images were successfully tested!")
        return
    
    accuracy = correct / total
    
    # Display results
    print("\n" + "=" * 70)
    print("📊 TEST RESULTS")
    print("=" * 70)
    print(f"\n🎯 Overall Accuracy: {correct}/{total} = {accuracy:.1%}")
    
    # Accuracy interpretation
    if accuracy >= 0.85:
        print("   🎉 EXCELLENT! Your model is performing great!")
        print("   ✅ Ready to deploy to Flutter app!")
    elif accuracy >= 0.70:
        print("   👍 GOOD! Model is working well.")
        print("   ✅ Good enough to use in production!")
    elif accuracy >= 0.60:
        print("   ⚠️  FAIR. Model works but could be better.")
        print("   Consider collecting more data or training longer.")
    else:
        print("   ❌ NEEDS IMPROVEMENT. Check your data quality.")
    
    # Per-class accuracy
    print("\n📈 Per-Class Performance:")
    print("   (How well does it recognize each type?)\n")
    for category in categories:
        total_cat = sum(confusion[category].values())
        if total_cat > 0:
            correct_cat = confusion[category][category]
            acc_cat = correct_cat / total_cat
            bar = "█" * int(acc_cat * 20)
            print(f"   {category:10s}: {acc_cat:6.1%} ({correct_cat}/{total_cat}) {bar}")
        else:
            print(f"   {category:10s}: No test images")
    
    # Confusion matrix
    print("\n🔄 Confusion Matrix:")
    print("   (Shows what the model confused with what)")
    print("\n   True →      " + "".join(f"{cat:10s}" for cat in categories))
    print("   Predicted ↓")
    for true_cat in categories:
        print(f"   {true_cat:10s}", end="")
        for pred_cat in categories:
            count = confusion[true_cat][pred_cat]
            if count > 0:
                if true_cat == pred_cat:
                    print(f"  ✓{count:7d} ", end="")
                else:
                    print(f"  ✗{count:7d} ", end="")
            else:
                print(f"  {'-':>7s} ", end="")
        print()
    
    # Common mistakes
    print("\n🔍 Most Common Mistakes:")
    mistakes = []
    for true_cat in categories:
        for pred_cat in categories:
            if true_cat != pred_cat and confusion[true_cat][pred_cat] > 0:
                mistakes.append((confusion[true_cat][pred_cat], true_cat, pred_cat))
    
    mistakes.sort(reverse=True)
    if mistakes:
        for count, true_cat, pred_cat in mistakes[:5]:
            print(f"   • Confused {true_cat:8s} as {pred_cat:8s}: {count} times")
    else:
        print("   🎉 No mistakes! Perfect predictions!")
    
    print("\n" + "=" * 70)
    
    # Recommendations
    print("\n💡 NEXT STEPS:")
    if accuracy >= 0.70:
        print("   ✅ Model is good enough to use!")
        print("   📱 Export to TFLite: python3 export_to_tflite.py")
        print("   🚀 Then integrate into Flutter app!")
    else:
        print("   ⚠️  Consider improving the model:")
        print("   • Collect more training images (aim for 100+ per class)")
        print("   • Remove blurry/incorrect images from dataset")
        print("   • Train for more epochs")
        print("   • Balance classes (equal images per category)")
    
    print("=" * 70)
    
    return accuracy

if __name__ == "__main__":
    test_your_model()